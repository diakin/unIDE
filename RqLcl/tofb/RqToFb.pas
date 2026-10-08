// ---------------------------------------------------------------------------
//  RqToFb - перевод исходника RapidQ в FreeBASIC перед сборкой fbc
//
//  Без VCL: используется unIDE и консольной утилитой rqtofb.
//
//  Каждый файл программы (главный и $INCLUDE) переводится в отдельный
//  файл в AOptions.OutDir; строки переводятся один к одному, перед ними -
//  "#line 0 "исходный файл"", поэтому fbc сообщает об ошибках по файлу и
//  строке исходника RapidQ. Длинная конструкция, собранная заново
//  (DIM, заголовок SUB), сохраняет число строк продолжениями " _".
//
//  Два прохода по программе в порядке включения файлов: первый собирает
//  объявления (DIM, DEFxxx, CONST, SUB/FUNCTION, DECLARE, TYPE, метки,
//  REDIM) и необъявленные переменные; второй переписывает текст.
//  $DEFINE и $IFDEF выполняет сам препроцессор (RapidQ меняет ими и
//  ключевые слова), в FreeBASIC они не передаются.
//
//  Правила - RqLcl/RAPIDQ_RULES.md:
//    - тип необъявленной переменной - по суффиксу, без суффикса DOUBLE
//      ($OPTION DIM меняет); имена с суффиксом переименовываются
//      (a$ -> a__s), FreeBASIC суффиксов у переменных не допускает;
//    - переменные модуля - Dim Shared (видны в SUB, как в RapidQ);
//      необъявленные - в заголовке главного файла; необъявленная внутри
//      SUB, которой нет в модуле, - локальная (Dim в строке заголовка SUB);
//    - присваивание переменной - правая часть в функции по типу слева
//      (RqNum, RqLong, RqStr... из rqrt.bi), перегрузку выбирает fbc;
//    - PRINT - каждый элемент в RqFmt, запятая как точка с запятой;
//    - параметры по значению (ByVal), объекты, массивы и UDT - по ссылке;
//    - обработчик события без @ (Button.OnClick = Proc) - с @.
//
//  Сообщения - строками "файл(строка) Warning: текст" и "... Error: текст",
//  как у dcc32: unIDE красит ошибки и переходит к строке.
// ---------------------------------------------------------------------------
unit RqToFb;

interface

uses
  SysUtils, Classes;

type
  TRqFbMode = (rfmSmart, rfmCompat);

  TRqFbOptions = record
    Mode: TRqFbMode;
    IncDirs: string;     // папки поиска $INCLUDE через ';'
    OutDir: string;      // куда писать переведённые файлы
  end;

  TRqFbResult = record
    MainOut: string;     // переведённый главный файл - его собирает fbc
    AppType: string;     // GUI или CONSOLE ($APPTYPE или по наличию QFORM...)
    Mode: TRqFbMode;     // режим с учётом строки '$RQFB в исходнике
    ErrorCount: Integer;
    WarningCount: Integer;
    // файл ресурсов ($RESOURCE) для fbc; '' - ресурсов нет
    ResourceFile: string;
  end;

// Перевести программу AMainFile. Сообщения - в AMessages. False - были
// ошибки (переведённые файлы всё равно записаны).
function RqToFbConvert(const AMainFile: string; const AOptions: TRqFbOptions;
                       AMessages: TStrings; var AResult: TRqFbResult): Boolean;

implementation

const
  // Ключевые слова и встроенные функции RapidQ (rapidq_ref/keyword.lst) и
  // слова, которые переменной быть не могут
  RqKeywordText =
    'FILEEXISTS BYVAL BYREF EXECUTE CEIL FLOOR MEMCMP CALL DIM REDIM AS ' +
    'CREATE IF THEN ELSE ELSEIF END EVENT INTEGER STRING SHORT LONG SINGLE ' +
    'DOUBLE WORD DWORD VARIANT BYTE TYPE EXTENDS PRINT LPRINT LFLUSH SUB ' +
    'MESSAGEBOX UNLOADLIBRARY LIBRARYINST FUNCTION SUBI FUNCTIONI ALIAS LIB ' +
    'DECLARE BIND CALLFUNC FOR TO NEXT STEP DO LOOP UNTIL WHILE WEND EXIT ' +
    'GOTO GOSUB RETURN SELECT CASE RANDOMIZE TIMER RND VAL CHR$ LEN RESTORE ' +
    'KILL RENAME RMDIR INKEY$ TIME$ DATE$ STRING$ ASC SPACE$ INPUT$ PLAYWAV ' +
    'ATN ATAN ASIN ACOS MID$ LEFT$ RIGHT$ INSERT$ REPLACE$ DELETE$ STR$ ' +
    'RTRIM$ LTRIM$ INSTR COMMAND$ COMMANDCOUNT PARAMVALCOUNT PARAMSTRCOUNT ' +
    'PARAMVAL PARAMSTR$ UCASE$ LCASE$ SOUND EXP LOG SGN GET$ CURDIR$ HEX$ ' +
    'READ DATA AND OR XOR NOT MOD INV SHL SHR INT FIX FRAC CINT CLNG ROUND ' +
    'SIN COS TAN ABS BIN$ REPLACESUBSTR$ CHDIR CONVBASE$ DEC INC DEFINT ' +
    'DEFSTR DEFDBL DEFSNG DEFBYTE DEFWORD DEFDWORD DEFLNG DEFSHORT DIR$ ' +
    'ENVIRON ENVIRON$ TALLY QUICKSORT CHDRIVE MKDIR DIREXISTS DOEVENTS ' +
    'UBOUND LBOUND SWAP IIF RGB SQR SHELL RUN CODEPTR CALLBACK VARTYPE ' +
    'SHOWMESSAGE MESSAGEDLG FIELD$ VARPTR VARPTR$ CONST SIZEOF IS WITH ' +
    'CONSTRUCTOR CLS COLOR LOCATE INPUT INP OUT POKE PEEK CSRLIN POS PCOPY ' +
    'SETCONSOLETITLE SLEEP MOUSEX MOUSEY ' +
    'LET REM PUBLIC PRIVATE SHARED STATIC RESULT SUPER THIS OPEN CLOSE EOF ' +
    'LOF FREEFILE SEEK APPEND OUTPUT BINARY RANDOM ACCESS LINE ON ERROR ' +
    'RESUME STOP SYSTEM TAB SPC USING PRESERVE ERASE ERR TRIM$ LCASE UCASE ' +
    'LEFT RIGHT MID CHR STR SPACE TRIM LTRIM RTRIM HEX OCT$ BIN';

  // Функции со знаком $, которые есть и в FreeBASIC
  FbStrFuncText =
    'CHR$ STR$ LEFT$ RIGHT$ MID$ UCASE$ LCASE$ SPACE$ STRING$ LTRIM$ ' +
    'RTRIM$ TRIM$ HEX$ OCT$ BIN$ DATE$ TIME$ COMMAND$ ENVIRON$ INKEY$ ' +
    'INPUT$ MKI$ MKL$ MKS$ MKD$ CURDIR$ DIR$';

  // Функции RapidQ со знаком $, которых в FreeBASIC нет
  RqOnlyStrFuncText =
    'INSERT$ REPLACE$ DELETE$ PARAMSTR$ GET$ REPLACESUBSTR$ CONVBASE$ ' +
    'FIELD$ VARPTR$ REVERSE$ STRF$';

  // Функции RapidQ со знаком $ -> функции rqrt.bi (у HEX$ RapidQ дополняет
  // до 8 знаков, у FreeBASIC - нет)
  RqFuncMapText =
    'INSERT$=RqInsert REPLACE$=RqReplace DELETE$=RqDelete ' +
    'REPLACESUBSTR$=RqReplaceSubStr CONVBASE$=RqConvBase FIELD$=RqField ' +
    'REVERSE$=RqReverse HEX$=RqHex DIR$=RqDir STRF$=RqStrF ' +
    'RESOURCE=RqResource RESOURCECOUNT=RqResourceCount ' +
    'EXTRACTRESOURCE=RqExtractResource';

  // Свойства и методы RapidQ, имена которых в FreeBASIC - ключевые слова:
  // .Pointer (QMEMORYSTREAM) -> .PointerAddr (rqstream.bi), .Type и .Peek
  // (QSOCKET) -> .Type_v, .Peek_v (rqsocket.bi)
  RqMemberMapText =
    'POINTER=PointerAddr DELETE=Delete_v TYPE=Type_v PEEK=Peek_v';

  // События с параметрами: типы параметров обработчика (R - ByRef, V -
  // ByVal; тип RapidQ). Обработчик, назначенный такому событию, получает
  // эти типы, какие бы ни были в его заголовке (Key AS WORD -> ByRef
  // Long): адрес процедуры передаётся в rqlcl.bi без преобразования, и
  // типы должны совпасть точно.
  RqEventSigText =
    'ONKEYDOWN=RLONG;VLONG ONKEYUP=RLONG;VLONG ONKEYPRESS=RLONG ' +
    'ONMOUSEDOWN=VLONG;VLONG;VLONG;VLONG ONMOUSEUP=VLONG;VLONG;VLONG;VLONG ' +
    'ONMOUSEMOVE=VLONG;VLONG;VLONG ONSELECTCELL=VLONG;VLONG;RLONG ' +
    'ONDRAWCELL=VLONG;VLONG;VLONG;RQRECT ONSETEDITTEXT=VLONG;VLONG;VSTRING ' +
    'ONDRAWITEM=VLONG;VLONG;RQRECT ' +
    // QTREEVIEW; у остальных классов OnChange без параметров - обработчик
    // без параметров (или только с Sender) этим не меняется
    'ONCHANGE=VLONG ONEXPAND=VLONG ONCOLLAPSE=VLONG ' +
    'ONCHANGING=VLONG;RLONG ONEXPANDING=VLONG;RLONG ONCOLLAPSING=VLONG;RLONG ' +
    // QLISTVIEW: OnChange (Index, Change) - под именем LVONCHANGE (у
    // QTREEVIEW параметр один), OnColumnClick (Column), OnKeyPressed (Key)
    'LVONCHANGE=VLONG;VLONG ONCOLUMNCLICK=VLONG ONKEYPRESSED=RLONG ' +
    // QSCROLLBAR: OnScroll (ScrollCode, ScrollPos); QHEADER: OnDrawSection
    // (Index, Pressed, Rect), OnSectionClick, OnSectionResize (Index),
    // OnSectionTrack (Index, Width, State)
    'ONSCROLL=VLONG;VLONG ONDRAWSECTION=VLONG;VLONG;RQRECT ' +
    'ONSECTIONCLICK=VLONG ONSECTIONRESIZE=VLONG ' +
    'ONSECTIONTRACK=VLONG;VLONG;VLONG ' +
    // WndProc (QFORM, QEDIT, QLISTBOX, QLABEL): Hwnd, Msg, wParam, lParam
    'WNDPROC=VLONG;VLONG;VLONG;VLONG ' +
    // QFORM OnHint (Hint); QLISTBOX, QCOMBOBOX OnMeasureItem (Index,
    // Height); QSTRINGGRID OnEllipsisClick (Col, Row), OnListDropDown (Col,
    // Row, S); QTREEVIEW OnDeletion, OnGetImageIndex, OnGetSelectedIndex
    // (Index), OnEdited (Index, S), OnEditing (Index, AllowEdit)
    'ONHINT=VSTRING ONMEASUREITEM=VLONG;RLONG ONELLIPSISCLICK=VLONG;VLONG ' +
    'ONLISTDROPDOWN=VLONG;VLONG;RSTRING ONDELETION=VLONG ONEDITED=VLONG;RSTRING ' +
    'ONEDITING=VLONG;RLONG ONGETIMAGEINDEX=VLONG ONGETSELECTEDINDEX=VLONG';

  // Запись в массив-свойство с двумя индексами: у свойства FreeBASIC
  // индекс один, поэтому Grid.Cell(c, r) = x -> Grid.SetCell(c, r, x)
  RqIndexedSetText =
    'CELL=SetCell SUBITEM=SetSubItem PIXEL=SetPixel';

  // Слова FreeBASIC, которыми переменная называться не может
  FbReservedText =
    'ACCESS ALIAS AND ANDALSO ANY APPEND AS ASM BASE BEEP BINARY BOOLEAN ' +
    'BYREF BYTE BYVAL CALL CASE CAST CDECL CHAIN CHDIR CIRCLE CLASS CLEAR ' +
    'CLOSE CLS COLOR COMMON CONST CONSTRUCTOR CONTINUE DATA DECLARE DEFINE ' +
    'DELETE DESTRUCTOR DIM DO DOUBLE DRAW DYNAMIC ELSE ELSEIF END ENUM EQV ' +
    'ERASE ERR ERROR EXIT EXPLICIT EXPORT EXTENDS EXTERN FALSE FIELD FOR ' +
    'FUNCTION GET GOSUB GOTO IF IMP IMPORT INPUT INTEGER IS KILL LET LIB ' +
    'LINE LOCAL LOCATE LOCK LONG LONGINT LOOP LPRINT MOD NAME NAMESPACE NEW ' +
    'NEXT NOT OBJECT OPEN OPERATOR OPTION OR ORELSE OUTPUT OVERLOAD PAINT ' +
    'PALETTE PASCAL PCOPY POINT POINTER POKE PRESET PRINT PRIVATE PROPERTY ' +
    'PROTECTED PSET PTR PUBLIC PUT RANDOM READ REDIM REM RESTORE RESUME ' +
    'RETURN SCOPE SCREEN SEEK SELECT SHARED SHL SHORT SHR SINGLE SLEEP ' +
    'STATIC STDCALL STEP STOP STRING SUB SWAP SYSTEM THEN THIS TO TRUE TYPE ' +
    'TYPEOF UBYTE UINTEGER ULONG ULONGINT UNION UNLOCK UNTIL USHORT USING ' +
    'VAR VIEW WEND WHILE WIDTH WINDOW WITH WRITE WSTRING XOR ZSTRING ' +
    'LEN VAL STR CHR ASC LEFT RIGHT MID INSTR ABS INT FIX SGN SQR TIMER RND ' +
    'POS';

  // Слова, которыми член Type FreeBASIC называться не может (Delete, Swap,
  // Type, Select, Case, New, Return проверены, fbc 1.10.1: "Duplicated
  // definition"); остальные слова FreeBASIC (Print, Get, Write, Line,
  // Open, Close...) членами быть могут
  FbBadMemberText =
    'DELETE SWAP TYPE SELECT CASE NEW RETURN IF THEN ELSE ELSEIF END FOR ' +
    'NEXT DO LOOP WHILE WEND UNTIL SUB FUNCTION DIM REDIM AS GOTO GOSUB ' +
    'EXIT CONST DECLARE PROPERTY OPERATOR CONSTRUCTOR DESTRUCTOR WITH ' +
    'SCOPE NAMESPACE ENUM UNION EXTENDS BYVAL BYREF AND OR NOT XOR MOD ' +
    'SHL SHR ANDALSO ORELSE CAST CONTINUE STATIC SHARED PUBLIC PRIVATE ' +
    'PROTECTED THIS BASE VAR LET CALL PEEK';

  // Классы RapidQ (объекты: передаются по ссылке, без преобразования)
  RqObjectText =
    'QFORM QBITMAP QCANVAS QBUTTON QCOOLBTN QSTRINGGRID QSTRINGLIST QLISTBOX ' +
    'QCOMBOBOX QOBJECT QGAUGE QOVALBTN QMENUITEM QMAINMENU QTIMER QFONT ' +
    'QIMAGE QPANEL QLABEL QRECT QRICHEDIT QEDIT QSTATUSBAR QCHECKBOX ' +
    'QPOPUPMENU QDIRTREE QFILELISTBOX QFILESTREAM QFONTDIALOG QGROUPBOX ' +
    'QIMAGELIST QSCROLLBOX QTABCONTROL QLISTVIEW QMEMORYSTREAM ' +
    'QNOTIFYICONDATA QOPENDIALOG QOUTLINE QRADIOBUTTON QREGISTRY QSAVEDIALOG ' +
    'QSCROLLBAR QSOCKET QTRACKBAR QGLASSFRAME QHEADER QSPLITTER QMYSQL ' +
    'QTREEVIEW QOLEOBJECT QDXSCREEN QDXIMAGELIST QDXTIMER QD3DFRAME ' +
    'QD3DLIGHT QD3DMESH QD3DMESHBUILDER QD3DVISUAL QD3DTEXTURE QD3DWRAP ' +
    'QD3DANIMATION QD3DANIMATIONSET QD3DFACE QD3DVECTOR QCLIPBOARD QPRINTER ' +
    'QAPPLICATION QCOMPORT QSCREEN';

  // Невидимые компоненты: внутри CREATE - без Parent (у QTIMER в rqlcl.bi
  // Parent есть от QCONTROL, но TTimer LCL - не элемент окна)
  RqNonVisualText =
    'QTIMER QOPENDIALOG QSAVEDIALOG QFONTDIALOG QCOLORDIALOG QSTRINGLIST ' +
    'QREGISTRY QFILESTREAM QMEMORYSTREAM QFONT QIMAGELIST QSOCKET QPRINTER ' +
    'QCLIPBOARD QAPPLICATION QSCREEN QOBJECT QBITMAP QNOTIFYICONDATA';

  // Классы, после которых программа - GUI ($APPTYPE не задан)
  RqGuiObjectText =
    'QFORM QBUTTON QCOOLBTN QLABEL QEDIT QPANEL QCANVAS QLISTBOX QCOMBOBOX ' +
    'QRICHEDIT QSTRINGGRID QCHECKBOX QRADIOBUTTON QGROUPBOX QIMAGE ' +
    'QTABCONTROL QLISTVIEW QTREEVIEW QSTATUSBAR QMAINMENU QPOPUPMENU ' +
    'QSCROLLBAR QTRACKBAR QSCROLLBOX QOVALBTN QOUTLINE QHEADER';

  CrLf = #13#10;
  // Параметр SUBI / FUNCTIONI (RqPList - в rqrt.bi)
  VariadicParam = 'ByRef RqParams As RqPList';
  ContinueMark = ' _' + #13#10;
  // номер первого ресурса $RESOURCE (RCDATA в exe); так же в rqrt.bi и DLL
  RqResourceBase = 20001;   // перенос строки внутри собранного заново

type
  TTokKind = (tkSpace, tkIdent, tkNumber, tkString, tkComment, tkDirective,
              tkOp);

  TTok = record
    Kind: TTokKind;
    Text: string;       // исходный текст
    Up: string;         // верхний регистр (слова, директивы)
    OutText: string;    // что выводится вместо Text
    Pre: string;        // вывод перед
    Post: string;       // вывод после
  end;

  TToks = array of TTok;

  TRqVar = class
  public
    Name: string;       // верхний регистр, с суффиксом
    FbName: string;
    RqType: string;     // DOUBLE, STRING, LONG, ... или имя класса / TYPE
    Scope: string;      // '' - модуль, иначе имя SUB/FUNCTION
    IsArray: Boolean;
    IsConst: Boolean;
    Explicit: Boolean;  // объявлена (DIM, DEF..., параметр, CONST)
    Assigned: Boolean;  // получает значение: Перем = ..., FOR, INC/DEC
  end;

  TRqProc = class
  public
    Name: string;       // верхний регистр, с суффиксом
    FbName: string;
    IsFunc: Boolean;
    RetType: string;
    DeclParams: string; // параметры FreeBASIC из DECLARE
    DeclAliases: string; // " : Dim ByRef ..." для параметров из DECLARE
    IsVariadic: Boolean; // SUBI / FUNCTIONI
    Declared: Boolean;
    FbParams: string;   // параметры FreeBASIC (DECLARE или заголовок)
    HasBody: Boolean;   // есть SUB/FUNCTION с телом (или DECLARE ... LIB)
  end;

  // Свой компонент RapidQ: TYPE Имя EXTENDS Класс (документация RapidQ,
  // глава 10). Собирается в первом проходе; во втором по нему выводится
  // Type FreeBASIC (в строке TYPE) и переходники событий (в строке
  // END TYPE).
  TRqTypeInfo = class
  public
    Name: string;             // верхний регистр
    Display: string;          // как в исходнике
    BaseClass: string;        // верхний регистр
    BaseDisplay: string;
    Members: TStringList;     // ИМЯ=вид: F поле, P поле с PROPERTY SET,
                              // E событие (AS EVENT), M SUB, N FUNCTION,
                              // S процедура PROPERTY SET
    MemberFb: TStringList;    // ИМЯ=имя в FreeBASIC
    MemberType: TStringList;  // ИМЯ=тип RapidQ (поле, FUNCTION; у E - шаблон)
    ParamCounts: TStringList; // ИМЯ=число параметров (M, N, S)
    Before: TStringList;      // строки перед Type (типы шаблонов событий)
    Decls: TStringList;       // строки внутри Type
    After: TStringList;       // строки после End Type
    Tail: TStringList;        // строки в END TYPE (переходники событий)
    Thunks: TStringList;      // переходник=Поле|КЛАСС|Событие|МЕТОД
    Variadic: TStringList;    // методы SUBI / FUNCTIONI (верхний регистр)
    Regs: string;             // подключение событий в начале конструктора
    HasCtor: Boolean;
    constructor Create;
    destructor Destroy; override;
    function Kind(const AUp: string): Char;
  end;

  TCondRec = record
    ParentActive: Boolean;
    Active: Boolean;
    ElseSeen: Boolean;
  end;

  TRqFbConv = class
  private
    FOpt: TRqFbOptions;
    FMsgs: TStrings;
    FPass: Integer;               // 1 - сбор, 2 - вывод
    FMainFile: string;
    FVars: TStringList;           // 'SCOPE|NAME' -> TRqVar
    FProcs: TStringList;          // NAME -> TRqProc
    FTypes: TStringList;          // имена TYPE
    FLabels: TStringList;
    FRedims: TStringList;         // имена, у которых есть REDIM
    FDefines: TStringList;        // NAME=замена
    FResources: TStringList;      // $RESOURCE: ИМЯ=полный путь ('' - не найден)
    FDoneFiles: TStringList;      // исходный файл (верхний регистр) -> вывод
    FOutNames: TStringList;       // занятые имена файлов вывода
    FWarnedNames: TStringList;    // о чём уже предупреждали
    FKeywords: TStringList;
    FFbStrFuncs: TStringList;
    FRqStrFuncs: TStringList;
    FFbReserved: TStringList;
    FObjClasses: TStringList;
    FGuiClasses: TStringList;
    FFuncMap: TStringList;        // ИМЯ$=функция rqrt.bi
    FMemberMap: TStringList;      // СВОЙСТВО=имя в .bi
    FIndexedSet: TStringList;     // СВОЙСТВО=метод записи
    FEventSigs: TStringList;      // СОБЫТИЕ=типы параметров обработчика
    FHandlerEvents: TStringList;  // ПРОЦЕДУРА=СОБЫТИЕ (из Объект.OnXxx = Процедура)
    FHandlerProcs: TStringList;   // процедуры - обработчики событий
    FBinds: TStringList;          // ПЕРЕМЕННАЯ=процедура (BIND ... TO)
    FSkipBody: Boolean;           // тело функции-обхода RapidQ пропускается
    FParamAliases: string;        // от ParseParams: " : Dim ByRef ..."
    FClassMembers: TStringList;   // КЛАСС.ИМЯ=P|M|E (RqClassMembersText)
    FAllMembers: TStringList;     // ИМЯ=P|M|E по всем классам
    FCreateStack: TStringList;    // CREATE: ИмяОбъекта=КЛАСС, внутренний - последний
    FCurFile: string;
    FCurLine: Integer;
    FCurProc: TRqProc;
    FInType: Boolean;
    FPlainType: string;           // запись TYPE (не свой компонент) - имя
    FFixBodies: string;           // свойства полей STRING*N - после END TYPE
    FCreateDepth: Integer;
    FTypeCheck: Boolean;
    FEscape: Boolean;
    FDefaultType: string;
    FByRefDefault: Boolean;
    FConds: array of TCondRec;
    FAppType: string;
    FHasGui: Boolean;
    FErrors: Integer;
    FWarnings: Integer;
    FLostLines: Integer;          // переводы строк, убранные сборкой заново
    FSourceMode: string;          // '$RQFB SMART|COMPAT из исходника
    FLineIsLabel: Boolean;
    FLibParams: Boolean;          // параметры DECLARE ... LIB (STRING - указатель)
    FInlineIf: Boolean;           // в строке однострочный IF (после THEN есть оператор)
    FGosubSites: TStringList;     // GOSUB/RETURN: ОБЛАСТЬ=число GOSUB в ней
                                  // (первый проход; '*' - модуль)
    FGosubProcNum: Integer;       // номер GOSUB в текущей SUB/FUNCTION
    FGosubModNum: Integer;        // номер GOSUB на уровне модуля
    FTypeInfos: TStringList;      // свои компоненты: ИМЯ -> TRqTypeInfo
    FCurType: TRqTypeInfo;        // внутри TYPE ... EXTENDS
    FTypeBody: Integer;           // 0 - уровень TYPE, 1 - SUB/FUNCTION,
                                  // 2 - CONSTRUCTOR, 3 - EVENT, 4 - PROPERTY SET
    FTypeWith: string;            // WITH внутри TYPE: T - сам объект, O - другой
    FCurMethodUp: string;         // метод своего компонента (верхний регистр)
    FBadMembers: TStringList;
    FLineBreaks: Integer;         // переводов строк в текущей строке

    procedure Msg(const ALevel, AText: string);
    procedure Warn(const AText: string);
    procedure Error(const AText: string);
    procedure WarnOnce(const AKey, AText: string);
    function CondActive: Boolean;

    // Разбор строки
    procedure Lex(const AText: string; var AToks: TToks);
    function NextSig(const AToks: TToks; AFrom, ATo: Integer): Integer;
    function PrevSig(const AToks: TToks; AFrom: Integer): Integer;
    function MatchParen(const AToks: TToks; AOpen, ATo: Integer): Integer;
    function IsOp(const AToks: TToks; AIdx: Integer; const AOp: string): Boolean;
    function IsWord(const AToks: TToks; AIdx: Integer; const AWord: string): Boolean;
    function ApplyDefines(const AText: string): string;
    function RangeText(const AToks: TToks; AFrom, ATo: Integer): string;
    function RawText(const AToks: TToks; AFrom, ATo: Integer): string;
    procedure ClearRange(var AToks: TToks; AFrom, ATo: Integer);
    procedure Rebuild(var AToks: TToks; AFrom, ATo: Integer; const AText: string);
    function CommentOut(const AText: string): string;

    // Имена и типы
    function SuffixOf(const AName: string): string;
    function BaseOf(const AName: string): string;
    function SuffixType(const ASuffix: string): string;
    function Mangle(const ADisplay: string): string;
    function NormType(const AUp: string): string;
    function FbType(const ARqType: string): string;
    function ConvFunc(const ARqType: string): string;
    function IsObjectType(const ARqType: string): Boolean;
    function IsNumericType(const ARqType: string): Boolean;
    function ParseType(const AToks: TToks; var AIdx: Integer; ATo: Integer;
                       var AStarLen: string): string;
    function FindVar(const AUp: string): TRqVar;
    function DeclareVar(const ADisplay, ARqType, AScope: string;
                        AIsArray, AExplicit, AIsConst: Boolean): TRqVar;
    function ResolveVar(const ADisplay: string; AIsArray: Boolean): TRqVar;
    function DefaultValueText(const ARqType: string): string;
    function MatchBracket(const AToks: TToks; AOpen, ATo: Integer): Integer;
    procedure WrapStrIndex(var AToks: TToks; AIdx, ATo: Integer; AVar: TRqVar);
    procedure RewriteStrSub(var AToks: TToks; AFrom, ATo: Integer);
    procedure FinishStrSub(var AToks: TToks; AFrom, ATo: Integer);
    function ProcessPlusPlus(var AToks: TToks; AFirst, ATo: Integer): Boolean;
    function FindProc(const AUp: string): TRqProc;
    function GetProc(const ADisplay: string): TRqProc;
    function ExprIsString(const AToks: TToks; AFrom, ATo: Integer): Boolean;
    function ExprIsNumber(const AToks: TToks; AFrom, ATo: Integer): Boolean;
    function EscapeString(const AText: string): string;

    // Операторы
    procedure ProcessLine(const AText: string; var AOut: string);
    procedure ProcessStatement(var AToks: TToks; AFrom, ATo: Integer);
    procedure ProcessExpr(var AToks: TToks; AFrom, ATo: Integer);
    procedure ProcessIdent(var AToks: TToks; AIdx, ATo: Integer);
    procedure ProcessAssignOrCall(var AToks: TToks; AFrom, ATo: Integer);
    procedure ProcessDim(var AToks: TToks; AFrom, ATo: Integer);
    procedure ProcessDef(var AToks: TToks; AFrom, ATo: Integer);
    procedure ProcessConst(var AToks: TToks; AFrom, ATo: Integer);
    procedure ProcessProcHeader(var AToks: TToks; AFrom, ATo: Integer);
    procedure ProcessBind(var AToks: TToks; AFrom, ATo: Integer);
    procedure ProcessCallFuncStmt(var AToks: TToks; AFrom, ATo: Integer);
    function CallFuncTarget(const AToks: TToks; AFrom, ATo: Integer;
                            out AProc: TRqProc): Boolean;
    function ProcPtrType(AProc: TRqProc): string;
    procedure UseDeclareParamNames(ANameIdx: Integer; AProc: TRqProc;
                                   var AParams, AAliases: string);
    procedure CallFuncExpr(var AToks: TToks; AIdx, AOpen, AClose: Integer);
    function CallbackShimBody(AProc: TRqProc; const AParams: string): string;
    procedure ProcessDeclare(var AToks: TToks; AFrom, ATo: Integer);
    function ParseParams(var AToks: TToks; AFrom, ATo: Integer;
                         const AScope: string): string;
    function RewriteCreate(const AText: string): string;
    function MemberKind(const AClassUp, AMemberUp: string): Char;
    function ClassKnown(const AClassUp: string): Boolean;
    function AnyMemberKind(const AMemberUp: string): Char;
    procedure ProcessTypeHeader(var AToks: TToks; AFrom, ATo: Integer);
    procedure ProcessField(var AToks: TToks; AFrom, ATo: Integer);
    procedure FixedStringField(var AToks: TToks; AFrom, ATo, ANameIdx,
      AOpenIdx, ACloseIdx: Integer; const AStarLen: string);
    procedure ProcessPrint(var AToks: TToks; AFrom, ATo: Integer);
    procedure ProcessIf(var AToks: TToks; AFrom, ATo: Integer);
    procedure ProcessFor(var AToks: TToks; AFrom, ATo: Integer);
    function GosubScope: string;
    procedure GosubVarNames(const AScope: string; var ASpName, AStkName: string);
    procedure ProcessGosub(var AToks: TToks; AFrom, ATo: Integer);
    procedure ProcessReturn(var AToks: TToks; AFrom, ATo: Integer);
    procedure ProcessIncDec(var AToks: TToks; AFrom, ATo: Integer);
    procedure SplitVariadicCall(var AToks: TToks; AFirst, ATo: Integer);
    procedure WrapVariadicArgs(var AToks: TToks; AFrom, ATo, ANameIdx: Integer;
                               AInParens: Boolean);
    function VariadicMember(const AToks: TToks; AMemberIdx: Integer): Boolean;
    procedure RewriteMemberCall(var AToks: TToks; AFirst, ATo: Integer);
    function ProcessDirective(var AToks: TToks; AFrom, ATo: Integer;
                              var AOut: string): Boolean;
    function WriteResources: string;
    procedure ProcessResource(var AToks: TToks; AFrom, ATo, AArgIdx: Integer;
                              const AOriginal: string; var AOut: string);
    function ResolveInclude(const AName: string; AAngle: Boolean): string;
    function ProcessFile(const AFileName: string; AIsMain: Boolean): string;
    function MainHeader: string;
    procedure EndOfPass1;

    // TYPE ... EXTENDS
    function FindTypeInfo(const AUp: string): TRqTypeInfo;
    function MemberFbName(const ADisplay: string): string;
    function TypeMemberCollides(const AUp: string): Boolean;
    procedure GlobalQualify(var AToks: TToks; AIdx: Integer);
    procedure FixMemberClash(AVar: TRqVar; const AScope: string);
    function EventSigFor(const AClassUp, AEventUp: string): string;
    function HandlerEventKey(const AToks: TToks; AFirst, AEventIdx: Integer): string;
    function SigParams(const ASig: string; ANames: TStrings;
                       const AScope: string; out ACount: Integer): string;
    function LocalsText(const AScope: string): string;
    function RewriteTypeText(const AText: string): string;
    function TypeStatement(var AToks: TToks; AFirst, ATo: Integer): Boolean;
    procedure TypeMethodHeader(var AToks: TToks; AFirst, ATo: Integer;
                               AIsSetter: Boolean);
    procedure TypeEventHeader(var AToks: TToks; AFirst, ATo: Integer);
    procedure TypeCtorHeader(var AToks: TToks; AFirst, ATo: Integer);
    procedure TypeField(var AToks: TToks; AFirst, ATo: Integer);
    procedure TypeEnd(var AToks: TToks; AFirst, ATo: Integer);
    function TypeAssign(var AToks: TToks; AFirst, AEq, ATo: Integer): Boolean;
    procedure TypeCallFunc(var AToks: TToks; AFirst, ATo: Integer);
    procedure AddThunk(const AName, ACompFb, AClassUp, AEventDisplay,
                       AMethUp: string);
  public
    constructor Create(const AOptions: TRqFbOptions; AMessages: TStrings);
    destructor Destroy; override;
    function Run(const AMainFile: string; var AResult: TRqFbResult): Boolean;
  end;

// ---------------------------------------------------------------------------
//  Служебное
// ---------------------------------------------------------------------------

procedure FillWordList(AList: TStringList; const AText: string);
var
  Words: TStringList;
  WordIdx: Integer;
begin
  AList.Sorted := True;
  AList.Duplicates := dupIgnore;
  Words := TStringList.Create;
  try
    Words.Text := StringReplace(Trim(AText), ' ', CrLf, [rfReplaceAll]);
    for WordIdx := 0 to Words.Count - 1 do
      if Trim(Words[WordIdx]) <> '' then
        AList.Add(UpperCase(Trim(Words[WordIdx])));
  finally
    Words.Free;
  end;
end;

// Событие RapidQ: OnXxx и WndProc (QFORM, QEDIT, QLISTBOX, QLABEL)
function IsEventName(const AUp: string): Boolean;
begin
  Result := (Copy(AUp, 1, 2) = 'ON') or (AUp = 'WNDPROC');
end;

function InList(AList: TStringList; const AUp: string): Boolean;
var
  Found: Integer;
begin
  Result := AList.Find(AUp, Found);
end;

constructor TRqTypeInfo.Create;
begin
  inherited Create;
  Members := TStringList.Create;
  MemberFb := TStringList.Create;
  MemberType := TStringList.Create;
  ParamCounts := TStringList.Create;
  Before := TStringList.Create;
  Decls := TStringList.Create;
  After := TStringList.Create;
  Tail := TStringList.Create;
  Thunks := TStringList.Create;
  Variadic := TStringList.Create;
end;

destructor TRqTypeInfo.Destroy;
begin
  Members.Free;
  MemberFb.Free;
  MemberType.Free;
  ParamCounts.Free;
  Before.Free;
  Decls.Free;
  After.Free;
  Tail.Free;
  Thunks.Free;
  Variadic.Free;
  inherited Destroy;
end;

// Вид члена (#0 - нет такого)
function TRqTypeInfo.Kind(const AUp: string): Char;
var
  ItemIdx: Integer;
begin
  ItemIdx := Members.IndexOfName(AUp);
  if ItemIdx < 0 then
    Result := #0
  else
    Result := Members.ValueFromIndex[ItemIdx][1];
end;

// Файл без учёта регистра букв (для Linux; в Windows - как есть)
function FindFileCI(const APath: string): string;
var
  Dir, NamePart: string;
  Found: TSearchRec;
begin
  Result := '';
  if FileExists(APath) or DirectoryExists(APath) then
  begin
    Result := ExpandFileName(APath);
    Exit;
  end;
  Dir := ExtractFilePath(APath);
  NamePart := ExtractFileName(APath);
  if Dir = '' then
    Exit;
  // папка в другом регистре букв (Object\QIni.inc при папке object)
  if not DirectoryExists(Dir) then
  begin
    Dir := ExcludeTrailingPathDelimiter(Dir);
    if (Dir = '') or (ExtractFileName(Dir) = '') or
       (ExtractFilePath(Dir) = Dir + PathDelim) then
      Exit;
    Dir := FindFileCI(Dir);
    if (Dir = '') or not DirectoryExists(Dir) then
      Exit;
  end;
  if FindFirst(IncludeTrailingPathDelimiter(Dir) + '*', faAnyFile, Found) = 0 then
  try
    repeat
      if CompareText(Found.Name, NamePart) = 0 then
      begin
        Result := ExpandFileName(IncludeTrailingPathDelimiter(Dir) + Found.Name);
        Exit;
      end;
    until FindNext(Found) <> 0;
  finally
    FindClose(Found);
  end;
end;

// Строка оканчивается продолжением " _" (вне строки в кавычках и
// комментария)
function EndsWithContinue(const AText: string): Boolean;
var
  CharIdx, LineStart, LastIdx: Integer;
  InQuote: Boolean;
begin
  Result := False;
  // последняя физическая строка (AText может быть уже собран из
  // нескольких)
  LineStart := Length(AText);
  while (LineStart > 0) and (AText[LineStart] <> #10) do
    Dec(LineStart);
  Inc(LineStart);
  // "_ 'комментарий" - тоже продолжение (ComPort.cmp)
  InQuote := False;
  LastIdx := Length(AText);
  for CharIdx := LineStart to Length(AText) do
  begin
    if AText[CharIdx] = '"' then
      InQuote := not InQuote
    else if (AText[CharIdx] = '''') and not InQuote then
    begin
      LastIdx := CharIdx - 1;
      Break;
    end;
  end;
  if InQuote then
    Exit;
  while (LastIdx >= LineStart) and (AText[LastIdx] in [' ', #9, #13]) do
    Dec(LastIdx);
  if (LastIdx < LineStart) or (AText[LastIdx] <> '_') then
    Exit;
  // перед "_" - не часть имени (пробел, кавычка, скобка...)
  if (LastIdx > LineStart) and
     (AText[LastIdx - 1] in ['A'..'Z', 'a'..'z', '0'..'9', '_']) then
    Exit;
  Result := True;
end;

function CountLineBreaks(const AText: string): Integer;
var
  CharIdx: Integer;
begin
  Result := 0;
  for CharIdx := 1 to Length(AText) do
    if AText[CharIdx] = #10 then
      Inc(Result);
end;

function RepeatText(const AText: string; ACount: Integer): string;
var
  Idx: Integer;
begin
  Result := '';
  for Idx := 1 to ACount do
    Result := Result + AText;
end;

// ---------------------------------------------------------------------------
//  TRqFbConv
// ---------------------------------------------------------------------------

// --- rqmembers: начало (создано tofb/gen_members.py, руками не править)
// Свойства (P), методы (M) и события (E) классов RapidQ - из документации
// (rapidq_ref/html_doc) и типов RqLcl/inc/*.bi. Нужен для CREATE ...
// END CREATE: какие слова внутри - свойства объекта.
// Формат: КЛАСС:ИМЯ=вид,...|
const
  RqClassMembersText =
    'APPLICATION:EXENAME=P,HANDLE=P,HELPCOMMAND=M,HELPCONTEXT=M,HELPFILE=P,HELPJUMP=M,HINTCOLOR=P,HINTHIDEPAUSE=P,HINTPAUSE=P,HINTSHORTPAUSE=P,ICOHANDLE=P,ICON=P,MINIMIZE=M,SHOWHINT=P,T' +
    'ERMINATE=M,TITLE=P|' +
    'CLIPBOARD:CLEAR=M,CLOSE=M,FORMAT=P,FORMATCOUNT=P,GETASHANDLE=M,GETASTEXT=M,HASFORMAT=M,OPEN=M,SETASHANDLE=M,SETASTEXT=M,TEXT=P|' +
    'PRINTER:ABORT=M,ABORTED=P,BEGINDOC=M,CIRCLE=M,COPIES=P,COPYMODE=P,COPYRECT=M,DRAW=M,ENDDOC=M,FILLRECT=M,FONT=P,FONTS=P,FONTSCOUNT=P,HANDLE=P,LINE=M,NEWPAGE=M,ORIENTATION=P,PAGEHEIG' +
    'HT=P,PAGENUMBER=P,PAGEWIDTH=P,PAINT=M,PRINTERINDEX=P,PRINTERS=P,PRINTERSCOUNT=P,PRINTING=P,PSET=M,RECTANGLE=M,ROUNDRECT=M,STRETCHDRAW=M,TEXTHEIGHT=M,TEXTOUT=M,TEXTRECT=M,TEXTWIDTH=' +
    'M,TITLE=P|' +
    'QAPPLICATION:EXENAME=P,HANDLE=P,HELPCOMMAND=M,HELPCONTEXT=M,HELPFILE=P,HELPJUMP=M,HINTCOLOR=P,HINTHIDEPAUSE=P,HINTPAUSE=P,HINTSHORTPAUSE=P,ICOHANDLE=P,ICON=P,MINIMIZE=M,OBJ=M,RESTO' +
    'RE=M,SHOWHINT=P,TERMINATE=M,TITLE=P|' +
    'QBITMAP:ALIGN=P,BMP=P,BMPHANDLE=P,CIRCLE=M,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,COPYMODE=P,COPYRECT=M,COPYRECTPTR=M,CURSOR=P,DRAW=M,EMPTY=P,ENABLED=P,FILLRECT=M,FONT=P,HANDLE=P,HEI' +
    'GHT=P,HIDE=M,HINT=P,LEFT=P,LINE=M,LOADFROMFILE=M,LOADFROMSTREAM=M,MONOCHROME=P,PAINT=M,PARENT=P,PIXEL=P,PIXELFORMAT=P,POPUPMENU=P,PSET=M,RECTANGLE=M,REPAINT=M,ROTATE=M,ROUNDRECT=M,' +
    'SAVETOFILE=M,SAVETOSTREAM=M,SETFOCUS=M,SETPIXEL=M,SHOW=M,SHOWHINT=P,STRETCHDRAW=M,TABORDER=P,TAG=P,TEMPNAME=M,TEXTHEIGHT=M,TEXTOUT=M,TEXTRECT=M,TEXTWIDTH=M,TOP=P,TRANSPARENT=P,TRAN' +
    'SPARENTCOLOR=P,TRANSPARENTMODE=P,VISIBLE=P,WIDTH=P|' +
    'QBUTTON:ALIGN=P,BMP=P,BMPHANDLE=P,CANCEL=P,CAPTION=P,CLICK=M,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,CURSOR=P,DEFAULT=P,ENABLED=P,FONT=P,HANDLE=P,HEIGHT=P,HIDE=M,HINT=P,KIND=P,LAYOUT=' +
    'P,LEFT=P,MODALRESULT=P,NUMBMPS=P,ONCLICK=E,ONKEYDOWN=E,ONKEYPRESS=E,ONKEYUP=E,ONMOUSEDOWN=E,ONMOUSEMOVE=E,ONMOUSEUP=E,PARENT=P,POPUPMENU=P,REPAINT=M,SETFOCUS=M,SHOW=M,SHOWHINT=P,SP' +
    'ACING=P,STARTDRAG=M,TABORDER=P,TAG=P,TOP=P,VISIBLE=P,WIDTH=P|' +
    'QCANVAS:ALIGN=P,CIRCLE=M,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,COPYMODE=P,COPYRECT=M,COPYRECTPTR=M,CURSOR=P,DRAW=M,ENABLED=P,FILLRECT=M,FONT=P,HANDLE=P,HEIGHT=P,HIDE=M,HINT=P,LEFT=P' +
    ',LINE=M,ONCLICK=E,ONDBLCLICK=E,ONMOUSEDOWN=E,ONMOUSEMOVE=E,ONMOUSEUP=E,ONPAINT=E,PAINT=M,PARENT=P,PIXEL=P,POPUPMENU=P,PSET=M,RECTANGLE=M,REPAINT=M,ROTATE=M,ROUNDRECT=M,SETFOCUS=M,S' +
    'ETPIXEL=M,SHOW=M,SHOWHINT=P,STRETCHDRAW=M,TABORDER=P,TAG=P,TEXTHEIGHT=M,TEXTOUT=M,TEXTRECT=M,TEXTWIDTH=M,TOP=P,VISIBLE=P,WIDTH=P|' +
    'QCHECKBOX:ALIGN=P,CAPTION=P,CHECKED=P,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,CURSOR=P,ENABLED=P,FONT=P,HANDLE=P,HEIGHT=P,HIDE=M,HINT=P,LEFT=P,ONCLICK=E,ONKEYDOWN=E,ONKEYPRESS=E,ONKEY' +
    'UP=E,ONMOUSEDOWN=E,ONMOUSEMOVE=E,ONMOUSEUP=E,PARENT=P,POPUPMENU=P,REPAINT=M,SETFOCUS=M,SHOW=M,SHOWHINT=P,TABORDER=P,TAG=P,TOP=P,VISIBLE=P,WIDTH=P|' +
    'QCLIPBOARD:CLEAR=M,CLOSE=M,FORMAT=P,FORMATCOUNT=P,GETASHANDLE=M,GETASTEXT=M,HASFORMAT=M,OBJ=M,OPEN=M,SETASHANDLE=M,SETASTEXT=M,TEXT=P|' +
    'QCOMBOBOX:ADDITEMS=M,ALIGN=P,CIRCLE=M,CLEAR=M,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,COPYMODE=P,COPYRECT=M,COPYRECTPTR=M,CURSOR=P,DELITEMS=M,DRAW=M,DROPDOWNCOUNT=P,ENABLED=P,FILLRECT' +
    '=M,FONT=P,HANDLE=P,HEIGHT=P,HIDE=M,HINT=P,INSERTITEM=M,ITEM=P,ITEMCOUNT=P,ITEMHEIGHT=P,ITEMINDEX=P,LEFT=P,LINE=M,LISTCALL=M,MAXLENGTH=P,ONCHANGE=E,ONDRAWITEM=E,ONKEYDOWN=E,ONKEYPRE' +
    'SS=E,ONKEYUP=E,ONMEASUREITEM=E,PAINT=M,PARENT=P,POPUPMENU=P,PSET=M,RECTANGLE=M,REPAINT=M,ROUNDRECT=M,SETFOCUS=M,SHOW=M,SHOWHINT=P,SORTED=P,STRETCHDRAW=M,STYLE=P,TABORDER=P,TAG=P,TE' +
    'XT=P,TEXTHEIGHT=M,TEXTOUT=M,TEXTRECT=M,TEXTWIDTH=M,TOP=P,VISIBLE=P,WIDTH=P|' +
    'QCOMPORT:ABORTALLIO=M,BAUDRATE=P,CLOSE=M,CONNECTED=P,DATABITS=P,HANDLE=P,INQUE=P,ONBREAK=E,ONCLOSE=E,ONERROR=E,ONOPEN=E,ONRING=E,ONRXCHAR=E,ONTXEMPTY=E,OPEN=M,OUTQUE=P,PARITY=P,PEN' +
    'DINGIO=P,PORT=P,PURGEIN=M,PURGEOUT=M,READ=M,READBUFSIZE=P,READSTRING=M,STOPBITS=P,WAITFORLASTIO=M,WRITE=M,WRITEBUFSIZE=P,WRITESTRING=M|' +
    'QCOOLBTN:ALIGN=P,ALLOWALLUP=P,BMP=P,BMPHANDLE=P,CAPTION=P,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,CURSOR=P,DOWN=P,ENABLED=P,FLAT=P,FONT=P,GROUPINDEX=P,HANDLE=P,HEIGHT=P,HIDE=M,HINT=P,' +
    'LAYOUT=P,LEFT=P,NUMBMPS=P,ONCLICK=E,ONMOUSEDOWN=E,ONMOUSEMOVE=E,ONMOUSEUP=E,PARENT=P,POPUPMENU=P,REPAINT=M,SETFOCUS=M,SHOW=M,SHOWHINT=P,SPACING=P,STARTDRAG=M,TABORDER=P,TAG=P,TOP=P' +
    ',VISIBLE=P,WIDTH=P|' +
    'QDIRTREE:ADDDIRTYPES=M,ADDDRIVETYPES=M,ALIGN=P,BORDERSTYLE=P,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,CURSOR=P,DELDIRTYPES=M,DELDRIVETYPES=M,DIRECTORY=P,ENABLED=P,FASTLOAD=P,FONT=P,FUL' +
    'LCOLLAPSE=M,FULLEXPAND=M,HANDLE=P,HEIGHT=P,HIDE=M,HIDESELECTION=P,HINT=P,INITIALDIR=P,LEFT=P,ONCHANGE=E,ONKEYDOWN=E,ONKEYPRESS=E,ONKEYUP=E,ONMOUSEDOWN=E,ONMOUSEMOVE=E,ONMOUSEUP=E,P' +
    'ARENT=P,POPUPMENU=P,READONLY=P,READONSTART=P,RELOAD=M,REPAINT=M,SETFOCUS=M,SHOW=M,SHOWHINT=P,TABORDER=P,TAG=P,TOP=P,VISIBLE=P,WIDTH=P|' +
    'QEDIT:ALIGN=P,AUTOSIZE=P,BORDERSTYLE=P,CHARCASE=P,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,CURSOR=P,EDITTEXT=P,ENABLED=P,FONT=P,HANDLE=P,HEIGHT=P,HIDE=M,HINT=P,INPUTMASK=P,ISMASKED=P,L' +
    'EFT=P,MAXLENGTH=P,MODIFIED=P,ONCHANGE=E,ONKEYDOWN=E,ONKEYPRESS=E,ONKEYUP=E,ONMOUSEDOWN=E,ONMOUSEMOVE=E,ONMOUSEUP=E,PARENT=P,PASSWORDCHAR=P,POPUPMENU=P,READONLY=P,REPAINT=M,SELLENGT' +
    'H=P,SELSTART=P,SELTEXT=P,SETFOCUS=M,SHOW=M,SHOWHINT=P,TABORDER=P,TAG=P,TEXT=P,TOP=P,VISIBLE=P,WIDTH=P,WNDPROC=E|' +
    'QFILELISTBOX:ADDFILETYPES=M,ALIGN=P,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,CURSOR=P,DELFILETYPES=M,DIRECTORY=P,DRIVE=P,ENABLED=P,EXTENDEDSELECT=P,FILENAME=P,FONT=P,HANDLE=P,HEIGHT=P,' +
    'HIDE=M,HINT=P,ITEM=P,ITEMCOUNT=P,ITEMHEIGHT=P,ITEMINDEX=P,LEFT=P,MASK=P,MULTISELECT=P,ONCHANGE=E,ONCLICK=E,ONDBLCLICK=E,ONKEYDOWN=E,ONKEYPRESS=E,ONKEYUP=E,ONMOUSEDOWN=E,ONMOUSEMOVE' +
    '=E,ONMOUSEUP=E,PARENT=P,POPUPMENU=P,REPAINT=M,SELCOUNT=P,SELECTED=P,SETFOCUS=M,SHOW=M,SHOWHINT=P,SHOWICONS=P,STRCALL=M,TABORDER=P,TAG=P,TOP=P,TOPINDEX=P,UPDATE=M,VISIBLE=P,WIDTH=P|' +
    'QFILESTREAM:CLOSE=M,COPYFROM=M,EOF=P,EXTRACTRES=M,HANDLE=P,LINECOUNT=P,LOADARRAY=M,OPEN=M,POSITION=P,READ=M,READBINSTR=M,READLINE=M,READNUM=M,READSTR=M,READUDT=M,SAVEARRAY=M,SEEK=M' +
    ',SIZE=P,WRITE=M,WRITEBINSTR=M,WRITELINE=M,WRITENUM=M,WRITESTR=M,WRITEUDT=M|' +
    'QFONT:ADDSTYLES=M,BOLD=P,CHARSET=P,COLOR=P,DELSTYLES=M,FONTCOUNT=P,FONTNAME=P,HANDLE=P,HASSTYLE=M,ITALIC=P,NAME=P,PITCH=P,SETSTYLE=M,SIZE=P,STRIKEOUT=P,UNDERLINE=P|' +
    'QFONTDIALOG:ADDOPTIONS=M,ADDSTYLES=M,COLOR=P,DELOPTIONS=M,DELSTYLES=M,EXECUTE=M,FONTCOUNT=P,FONTNAME=P,GETFONT=M,MAXFONTSIZE=P,MINFONTSIZE=P,NAME=P,ONAPPLY=E,SETFONT=M,SIZE=P,STRCA' +
    'LL=M|' +
    'QFORM:ADDBORDERICONS=M,ALIGN=P,AUTOSCROLL=P,BORDERSTYLE=P,CAPTION=P,CENTER=M,CIRCLE=M,CLIENTHEIGHT=P,CLIENTWIDTH=P,CLOSE=M,COLOR=P,COPYMODE=P,COPYRECT=M,COPYRECTPTR=M,CURSOR=P,DELB' +
    'ORDERICONS=M,DRAW=M,ENABLED=P,FILLRECT=M,FONT=P,FORMSTYLE=P,HANDLE=P,HEIGHT=P,HIDE=M,HIDETITLEBAR=M,HINT=P,ICOHANDLE=P,ICON=P,KEYPREVIEW=P,LEFT=P,LINE=M,MODALRESULT=P,ONCLICK=E,ONC' +
    'LOSE=E,ONHINT=E,ONKEYDOWN=E,ONKEYPRESS=E,ONKEYUP=E,ONMOUSEDOWN=E,ONMOUSEMOVE=E,ONMOUSEUP=E,ONPAINT=E,ONRESIZE=E,ONSHOW=E,PAINT=M,PARENT=P,PIXEL=M,POPUPMENU=P,PSET=M,RECTANGLE=M,REP' +
    'AINT=M,ROTATE=M,ROUNDRECT=M,SETFOCUS=M,SETPIXEL=M,SHAPEFORM=M,SHOW=M,SHOWHINT=P,SHOWMODAL=M,SHOWTITLEBAR=M,STRETCHDRAW=M,TABORDER=P,TAG=P,TEXTHEIGHT=M,TEXTOUT=M,TEXTRECT=M,TEXTWIDT' +
    'H=M,TOP=P,VISIBLE=P,WIDTH=P,WINDOWSTATE=P,WNDPROC=E|' +
    'QGAUGE:ALIGN=P,BACKCOLOR=P,BORDERSTYLE=P,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,CURSOR=P,ENABLED=P,FONT=P,FORECOLOR=P,HANDLE=P,HEIGHT=P,HIDE=M,HINT=P,KIND=P,LEFT=P,MAX=P,MIN=P,ONCLIC' +
    'K=E,ONDBLCLICK=E,ONMOUSEDOWN=E,ONMOUSEMOVE=E,ONMOUSEUP=E,PARENT=P,POPUPMENU=P,POSITION=P,REPAINT=M,SETFOCUS=M,SHOW=M,SHOWHINT=P,SHOWTEXT=P,TABORDER=P,TAG=P,TOP=P,VISIBLE=P,WIDTH=P|' +
    'QGLASSFRAME:ALIGN=P,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,CURSOR=P,HANDLE=P,HEIGHT=P,HINT=P,LEFT=P,MOVEABLE=P,PARENT=P,POPUPMENU=P,SHOWHINT=P,TOP=P,TRANSPARENCY=P,TRANSPARENTCOLOR=P' +
    ',WIDTH=P|' +
    'QGROUPBOX:ALIGN=P,CAPTION=P,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,CURSOR=P,ENABLED=P,FONT=P,HANDLE=P,HEIGHT=P,HIDE=M,HINT=P,LEFT=P,ONCLICK=E,ONDBLCLICK=E,ONMOUSEDOWN=E,ONMOUSEMOVE=E' +
    ',ONMOUSEUP=E,PARENT=P,POPUPMENU=P,REPAINT=M,SETFOCUS=M,SHOW=M,SHOWHINT=P,TABORDER=P,TAG=P,TOP=P,VISIBLE=P,WIDTH=P|' +
    'QHEADER:ADDSECTIONS=M,ALIGN=P,CIRCLE=M,CLEAR=M,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,COPYMODE=P,COPYRECT=M,COPYRECTPTR=M,CURSOR=P,DRAW=M,ENABLED=P,FILLRECT=M,FONT=P,HANDLE=P,HEIGHT=' +
    'P,HIDE=M,HINT=P,HOTTRACK=P,LEFT=P,LINE=M,ONDRAWSECTION=E,ONMOUSEDOWN=E,ONMOUSEMOVE=E,ONMOUSEUP=E,ONRESIZE=E,ONSECTIONCLICK=E,ONSECTIONRESIZE=E,ONSECTIONTRACK=E,PAINT=M,PARENT=P,PIX' +
    'EL=P,POPUPMENU=P,PSET=M,RECTANGLE=M,REPAINT=M,ROTATE=M,ROUNDRECT=M,SECTIONS=P,SECTIONSCOUNT=P,SETFOCUS=M,SETPIXEL=M,SHOW=M,SHOWHINT=P,STRETCHDRAW=M,TABORDER=P,TAG=P,TEXTHEIGHT=M,TE' +
    'XTOUT=M,TEXTRECT=M,TEXTWIDTH=M,TOP=P,VISIBLE=P,WIDTH=P|' +
    'QHEADERSECTION:ALIGNMENT=P,ALLOWCLICK=P,CAPTION=P,MAXWIDTH=P,MINWIDTH=P,STYLE=P,WIDTH=P|' +
    'QIMAGE:ALIGN=P,AUTOSIZE=P,BMP=P,BMPHANDLE=P,CENTER=P,CENTERIMAGE=M,CIRCLE=M,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,COPYMODE=P,COPYRECT=M,COPYRECTPTR=M,CURSOR=P,DRAW=M,ENABLED=P,FILLR' +
    'ECT=M,FONT=P,HANDLE=P,HEIGHT=P,HIDE=M,HINT=P,ICOHANDLE=P,ICON=P,INCREMENTALDISPLAY=P,LEFT=P,LINE=M,ONCLICK=E,ONDBLCLICK=E,ONMOUSEDOWN=E,ONMOUSEMOVE=E,ONMOUSEUP=E,PAINT=M,PARENT=P,P' +
    'IXEL=P,POPUPMENU=P,PSET=M,RECTANGLE=M,REPAINT=M,ROTATE=M,ROUNDRECT=M,SETFOCUS=M,SETPIXEL=M,SHOW=M,SHOWHINT=P,STRETCH=P,STRETCHDRAW=M,TABORDER=P,TAG=P,TEXTHEIGHT=M,TEXTOUT=M,TEXTREC' +
    'T=M,TEXTWIDTH=M,TOP=P,TRANSPARENT=P,VISIBLE=P,WIDTH=P|' +
    'QIMAGELIST:ADDBMPFILE=M,ADDBMPHANDLE=M,ADDICOFILE=M,ADDICOHANDLE=M,BKCOLOR=P,BLENDCOLOR=P,CLEAR=M,COUNT=P,DELETE=M,DELETE_V=M,DRAW=M,DRAWINGSTYLE=P,DRAWPTR=M,GETBMP=P,GETICO=P,HAND' +
    'LE=P,HEIGHT=P,IMAGETYPE=P,INSERTBMPFILE=M,INSERTBMPHANDLE=M,INSERTICOFILE=M,INSERTICOHANDLE=M,LISTCALL=M,MASKED=P,WIDTH=P|' +
    'QLABEL:ALIGN=P,ALIGNMENT=P,ANGLE=P,AUTOSIZE=P,CAPTION=P,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,CURSOR=P,ENABLED=P,FONT=P,HANDLE=P,HEIGHT=P,HIDE=M,HINT=P,LABELSTYLE=P,LAYOUT=P,LEFT=P,' +
    'LOWERCOLOR=P,ONCLICK=E,ONDBLCLICK=E,ONMOUSEDOWN=E,ONMOUSEMOVE=E,ONMOUSEUP=E,PARENT=P,POPUPMENU=P,REPAINT=M,SETFOCUS=M,SHOW=M,SHOWHINT=P,TABORDER=P,TAG=P,TOP=P,TRANSPARENT=P,UPPERCO' +
    'LOR=P,VISIBLE=P,WIDTH=P,WNDPROC=E,WORDWRAP=P|' +
    'QLISTBOX:ADDITEMS=M,ALIGN=P,BORDERSTYLE=P,CIRCLE=M,CLEAR=M,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,COLUMNS=P,COPYMODE=P,COPYRECT=M,COPYRECTPTR=M,CURSOR=P,DELITEMS=M,DRAW=M,ENABLED=P,E' +
    'XTENDEDSELECT=P,FILLRECT=M,FONT=P,HANDLE=P,HEIGHT=P,HIDE=M,HINT=P,INSERTITEM=M,ITEM=P,ITEMCOUNT=P,ITEMHEIGHT=P,ITEMINDEX=P,LEFT=P,LINE=M,LISTCALL=M,LOADFROMFILE=M,MULTISELECT=P,ONC' +
    'LICK=E,ONDBLCLICK=E,ONDRAWITEM=E,ONENTER=E,ONKEYDOWN=E,ONKEYPRESS=E,ONKEYUP=E,ONMEASUREITEM=E,ONMOUSEDOWN=E,ONMOUSEMOVE=E,ONMOUSEUP=E,PAINT=M,PARENT=P,POPUPMENU=P,PSET=M,RECTANGLE=' +
    'M,REPAINT=M,ROUNDRECT=M,SAVETOFILE=M,SELCOUNT=P,SELECTED=P,SETFOCUS=M,SHOW=M,SHOWHINT=P,SORTED=P,STRETCHDRAW=M,STYLE=P,TABORDER=P,TABWIDTH=P,TAG=P,TEXT=P,TEXTHEIGHT=M,TEXTOUT=M,TEX' +
    'TRECT=M,TEXTWIDTH=M,TOP=P,TOPINDEX=P,VISIBLE=P,WIDTH=P,WNDPROC=E|' +
    'QLISTCOLUMN:CAPTION=P,WIDTH=P|' +
    'QLISTITEM:CAPTION=P,CHECKED=P,HANDLE=P,IMAGEINDEX=P,INDEX=P,SELECTED=P,STATEINDEX=P|' +
    'QLISTVIEW:ADDCOLUMNS=M,ADDITEMS=M,ADDSUBITEM=M,ALIGN=P,BORDERSTYLE=P,CHECKBOXES=P,CLEAR=M,CLEARCOLUMNS=M,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,COLUMN=P,COLUMNCLICK=P,COLUMNSCOUNT=P,' +
    'CURSOR=P,DELITEMS=M,DELSUBITEM=M,ENABLED=P,FONT=P,GRIDLINES=P,HANDLE=P,HEIGHT=P,HIDE=M,HIDESELECTION=P,HINT=P,HOTTRACK=P,INSERTITEM=M,INSERTSUBITEM=M,ITEM=P,ITEMCOUNT=P,ITEMINDEX=P' +
    ',LARGEIMAGES=P,LEFT=P,MULTISELECT=P,ONCHANGE=E,ONCLICK=E,ONCOLUMNCLICK=E,ONDBLCLICK=E,ONKEYDOWN=E,ONKEYPRESS=E,ONKEYPRESSED=E,ONKEYUP=E,ONMOUSEDOWN=E,ONMOUSEMOVE=E,ONMOUSEUP=E,PARE' +
    'NT=P,POPUPMENU=P,READONLY=P,REPAINT=M,ROWSELECT=P,SELCOUNT=P,SELECTED=P,SETFOCUS=M,SETSUBITEM=M,SHOW=M,SHOWCOLUMNHEADERS=P,SHOWHINT=P,SMALLIMAGES=P,SORTTYPE=P,STATEIMAGES=P,STRCALL' +
    '=M,SUBITEM=P,SWAPITEM=M,TABORDER=P,TAG=P,TOP=P,VIEWSTYLE=P,VISIBLE=P,WIDTH=P|' +
    'QMAINMENU:ADDITEMS=M,ALIGN=P,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,CURSOR=P,DELINDEX=M,DELITEMS=M,ENABLED=P,FONT=M,HANDLE=P,HEIGHT=P,HIDE=M,HINT=P,INSERT=M,LEFT=P,MENUCALL=M,PARENT=' +
    'P,POPUPMENU=P,REPAINT=M,SETFOCUS=M,SHOW=M,SHOWHINT=P,TABORDER=P,TAG=P,TOP=P,VISIBLE=P,WIDTH=P|' +
    'QMEMORYSTREAM:CLOSE=M,COPYFROM=M,EOF=P,EXTRACTRES=M,LINECOUNT=P,LOADARRAY=M,MEMCOPYFROM=M,MEMCOPYTO=M,POINTER=P,POINTERADDR=P,POSITION=P,READ=M,READBINSTR=M,READLINE=M,READNUM=M,RE' +
    'ADSTR=M,READUDT=M,SAVEARRAY=M,SEEK=M,SIZE=P,WRITE=M,WRITEBINSTR=M,WRITELINE=M,WRITENUM=M,WRITESTR=M,WRITEUDT=M|' +
    'QMENUITEM:ADDITEMS=M,ALIGN=P,CAPTION=P,CHECKED=P,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,COMMAND=P,COUNT=P,CURSOR=P,DELINDEX=M,DELITEMS=M,ENABLED=P,FONT=M,HANDLE=P,HEIGHT=P,HIDE=M,HIN' +
    'T=P,INSERT=M,LEFT=P,MENUCALL=M,MENUINDEX=P,ONCLICK=E,PARENT=P,POPUPMENU=P,RADIOITEM=P,REPAINT=M,SETFOCUS=M,SHORTCUT=P,SHOW=M,SHOWHINT=P,TABORDER=P,TAG=P,TOP=P,VISIBLE=P,WIDTH=P|' +
    'QMYSQL:CLOSE=M,COLCOUNT=P,CONNECT=M,CONNECTED=P,CREATEDB=M,DB=P,DBCOUNT=P,DROPDB=M,ESCAPESTRING=M,FETCHFIELD=M,FETCHLENGTHS=M,FETCHROW=M,FIELDCOUNT=P,FIELDSEEK=M,LENGTH=P,QUERY=M,R' +
    'EALCONNECT=M,REFRESH=M,ROW=P,ROWBLOB=M,ROWCOUNT=P,ROWSEEK=M,SELECTDB=M,TABLE=P,TABLECOUNT=P|' +
    'QNOTIFYICONDATA:|' +
    'QOBJECT:|' +
    'QOLECONTAINER:ALIGN=P,ALLOWINPLACE=P,AUTOSHOW=P,BORDERSTYLE=P,COLOR=P,CREATEOBJECT=M,CURSOR=P,ENABLED=P,FREE=M,HANDLE=P,HEIGHT=P,HINT=P,INVOKE=M,LEFT=P,MODIFIED=P,ONKEYDOWN=E,ONKEY' +
    'PRESS=E,ONKEYUP=E,ONMOUSEDOWN=E,ONMOUSEMOVE=E,ONMOUSEUP=E,ONOBJECTMOVE=E,ONRESIZE=E,PARENT=P,SHOWHINT=P,SIZEMODE=P,STATE=P,TABORDER=P,TAG=P,TOP=P,VISIBLE=P,WIDTH=P|' +
    'QOLEOBJECT:CODEPAGE=M,CREATEOBJECT=M,CREATEREMOTE=M,DOCUMENTDIRECTION=M,DUMMY=M,DUMMYPARAM=M,FORMATOPEN=M,FREE=M,GETIDOFNAME=M,GETOBJECT=M,INVOKE=M,INVOKECOPY=M,NOENCODINGDIALOG=M,' +
    'OPENANDREPAIR=M,OPENCONFLICTDOCUMENT=M,VISIBLE=M|' +
    'QOPENDIALOG:CAPTION=P,EXECUTE=M,FILENAME=P,FILTER=P,FILTERINDEX=P,INITIALDIR=P|' +
    'QOUTLINE:ADDCHILD=M,ADDLINES=M,ADDOPTIONS=M,ALIGN=P,BMPCLOSED=P,BMPHANDLECLOSED=P,BMPHANDLELEAF=P,BMPHANDLEMINUS=P,BMPHANDLEOPEN=P,BMPHANDLEPLUS=P,BMPLEAF=P,BMPMINUS=P,BMPOPEN=P,BM' +
    'PPLUS=P,BORDERSTYLE=P,CLEAR=M,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,CURSOR=P,DELLINES=M,DELOPTIONS=M,ENABLED=P,FONT=P,FULLCOLLAPSE=M,FULLEXPAND=M,HANDLE=P,HEIGHT=P,HIDE=M,HINT=P,INS' +
    'ERT=M,ITEM=P,ITEMCOUNT=P,ITEMHEIGHT=P,ITEMINDEX=P,ITEMLEVEL=M,ITEMSEPARATOR=P,LEFT=P,LINECOUNT=P,ONCLICK=E,ONDBLCLICK=E,OUTLINECALL=M,OUTLINESTYLE=P,PARENT=P,POPUPMENU=P,REPAINT=M,' +
    'ROW=P,SCROLLBARS=P,SETFOCUS=M,SHOW=M,SHOWHINT=P,TABORDER=P,TAG=P,TOP=P,VISIBLE=P,WIDTH=P|' +
    'QOVALBTN:ALIGN=P,BMP=P,BMPHANDLE=P,CAPTION=P,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,COLORHIGHLIGHT=P,COLORSHADOW=P,CURSOR=P,DOWN=P,ENABLED=P,FLAT=P,FONT=P,GROUPINDEX=P,HANDLE=P,HEIGH' +
    'T=P,HIDE=M,HINT=P,LAYOUT=P,LEFT=P,NUMBMPS=P,ONCLICK=E,ONMOUSEDOWN=E,ONMOUSEMOVE=E,ONMOUSEUP=E,PARENT=P,POPUPMENU=P,REPAINT=M,SETFOCUS=M,SHOW=M,SHOWHINT=P,SPACING=P,STARTDRAG=M,TABO' +
    'RDER=P,TAG=P,TOP=P,TRANSPARENT=P,TRANSPARENTCOLOR=P,VISIBLE=P,WIDTH=P|' +
    'QPANEL:ALIGN=P,ALIGNMENT=P,BEVELINNER=P,BEVELOUTER=P,BEVELWIDTH=P,BORDERSTYLE=P,BVNONE=P,CAPTION=P,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,CURSOR=P,ENABLED=P,FONT=P,HANDLE=P,HEIGHT=P,' +
    'HIDE=M,HINT=P,LEFT=P,ONCLICK=E,ONDBLCLICK=E,ONMOUSEDOWN=E,ONMOUSEMOVE=E,ONMOUSEUP=E,PARENT=P,POPUPMENU=P,REPAINT=M,SETFOCUS=M,SHOW=M,SHOWHINT=P,TABORDER=P,TAG=P,TOP=P,VISIBLE=P,WID' +
    'TH=P|' +
    'QPOPUPMENU:ADDITEMS=M,ALIGN=P,ALIGNMENT=P,AUTOPOPUP=P,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,CURSOR=P,DELINDEX=M,DELITEMS=M,ENABLED=P,FONT=M,HANDLE=P,HEIGHT=P,HIDE=M,HINT=P,INSERT=M,' +
    'LEFT=P,MENUCALL=M,ONPOPUP=E,PARENT=P,POPUP=M,POPUPMENU=P,REPAINT=M,SETFOCUS=M,SHOW=M,SHOWHINT=P,TABORDER=P,TAG=P,TOP=P,VISIBLE=P,WIDTH=P,WINDOWHANDLE=P|' +
    'QPRINTER:ABORT=M,ABORTED=P,BEGINDOC=M,CAPABILITIES=M,CIRCLE=M,COPIES=P,COPYMODE=P,COPYRECT=M,COPYRECTPTR=M,DRAW=M,ENDDOC=M,FILLRECT=M,FONT=M,FONTS=P,FONTSCOUNT=P,HANDLE=P,LINE=M,NE' +
    'WPAGE=M,OBJ=M,ORIENTATION=P,PAGEHEIGHT=P,PAGENUMBER=P,PAGEWIDTH=P,PAINT=M,PIXEL=M,PRINTERINDEX=P,PRINTERS=P,PRINTERSCOUNT=P,PRINTING=P,PSET=M,RECTANGLE=M,ROTATE=M,ROUNDRECT=M,SETPI' +
    'XEL=M,STRETCHDRAW=M,TEXTHEIGHT=M,TEXTOUT=M,TEXTRECT=M,TEXTWIDTH=M,TITLE=P|' +
    'QPRINTERCAPS:COLLATE=P,COPIES=P,ORIENTATION=P|' +
    'QRADIOBUTTON:ALIGN=P,CAPTION=P,CHECKED=P,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,CURSOR=P,ENABLED=P,FONT=P,HANDLE=P,HEIGHT=P,HIDE=M,HINT=P,LEFT=P,ONCLICK=E,ONKEYDOWN=E,ONKEYPRESS=E,ON' +
    'KEYUP=E,ONMOUSEDOWN=E,ONMOUSEMOVE=E,ONMOUSEUP=E,PARENT=P,POPUPMENU=P,REPAINT=M,SETFOCUS=M,SHOW=M,SHOWHINT=P,TABORDER=P,TAG=P,TOP=P,VISIBLE=P,WIDTH=P|' +
    'QRECT:|' +
    'QREGISTRY:CLOSEKEY=M,CREATEKEY=M,CURRENTKEY=P,CURRENTPATH=P,DELETEKEY=M,DELETEVALUE=M,GETDATASIZE=P,GETDATATYPE=P,HASSUBKEYS=P,KEYEXISTS=M,KEYITEM=M,KEYITEMCOUNT=P,MOVEKEY=M,OPENKE' +
    'Y=M,READBINARY=M,READFLOAT=M,READINTEGER=M,READSTRING=M,REGISTRYCONNECT=M,RENAMEVALUE=M,ROOTKEY=P,VALUEEXISTS=M,VALUEITEM=M,VALUEITEMCOUNT=P,WRITEBINARY=M,WRITEFLOAT=M,WRITEINTEGER' +
    '=M,WRITESTRING=M|' +
    'QRICHEDIT:ADDSTRING=M,ADDSTRINGS=M,ALIGN=P,ALIGNMENT=P,BORDERSTYLE=P,CLEAR=M,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,COPYTOCLIPBOARD=M,CURSOR=P,CUTTOCLIPBOARD=M,ENABLED=P,FONT=P,HANDL' +
    'E=P,HEIGHT=P,HIDE=M,HIDESCROLLBARS=P,HIDESELECTION=P,HINT=P,LEFT=P,LINE=P,LINECOUNT=P,LOADFROMFILE=M,LOADFROMSTREAM=M,MODIFIED=P,ONCHANGE=E,ONKEYDOWN=E,ONKEYPRESS=E,ONKEYUP=E,ONMOU' +
    'SEDOWN=E,ONMOUSEMOVE=E,ONMOUSEUP=E,PARENT=P,PASTEFROMCLIPBOARD=M,PLAINTEXT=P,POPUPMENU=P,READONLY=P,REPAINT=M,SAVETOFILE=M,SAVETOSTREAM=M,SCROLLBARS=P,SELATTRIBUTES=P,SELECTALL=M,S' +
    'ELLENGTH=P,SELSTART=P,SELTEXT=P,SETFOCUS=M,SHOW=M,SHOWHINT=P,TABORDER=P,TAG=P,TEXT=P,TOP=P,VISIBLE=P,WANTTABS=P,WHEREX=P,WHEREY=P,WIDTH=P,WORDWRAP=P|' +
    'QSAVEDIALOG:CAPTION=P,EXECUTE=M,FILENAME=P,FILTER=P,FILTERINDEX=P,INITIALDIR=P|' +
    'QSCREEN:CURSOR=P,HEIGHT=P,MOUSEX=P,MOUSEY=P,OBJ=M,WIDTH=P|' +
    'QSCROLLBAR:ALIGN=P,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,CURSOR=P,ENABLED=P,FONT=M,HANDLE=P,HEIGHT=P,HIDE=M,HINT=P,KIND=P,LARGECHANGE=P,LEFT=P,MAX=P,MIN=P,ONCHANGE=E,ONKEYDOWN=E,ONK' +
    'EYPRESS=E,ONKEYUP=E,ONSCROLL=E,PAGESIZE=P,PARENT=P,POPUPMENU=P,POSITION=P,REPAINT=M,SETFOCUS=M,SHOW=M,SHOWHINT=P,SMALLCHANGE=P,TABORDER=P,TAG=P,TOP=P,VISIBLE=P,WIDTH=P|' +
    'QSCROLLBOX:ALIGN=P,AUTOSCROLL=P,BORDERSTYLE=P,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,CURSOR=P,ENABLED=P,FONT=P,HANDLE=P,HEIGHT=P,HIDE=M,HINT=P,HORZINCREMENT=P,HORZMARGIN=P,HORZPOSITI' +
    'ON=P,HORZRANGE=P,HORZTRACKING=P,HORZVISIBLE=P,LEFT=P,ONCLICK=E,ONDBLCLICK=E,ONMOUSEDOWN=E,ONMOUSEMOVE=E,ONMOUSEUP=E,ONRESIZE=E,PARENT=P,POPUPMENU=P,REPAINT=M,SETFOCUS=M,SHOW=M,SHOW' +
    'HINT=P,TABORDER=P,TAG=P,TOP=P,VERTINCREMENT=P,VERTMARGIN=P,VERTPOSITION=P,VERTRANGE=P,VERTTRACKING=P,VERTVISIBLE=P,VISIBLE=P,WIDTH=P|' +
    'QSOCKET:ACCEPT=M,ASYNCNOTIFY=M,CLOSE=M,CONNECT=M,CONNECTIONREADY=M,FAMILY=P,GETHOSTIP=M,GETHOSTNAME=M,GETPEERNAME=M,ISCLIENTREADY=M,ISSERVERREADY=M,LPARAM=P,MYSOCKET=P,OPEN=M,PAREN' +
    'T=P,PEEK=M,PEEK_V=M,PROTOCOL=P,READ=M,READBYTE=M,READLINE=M,RECVTEXT=M,TAG=P,TRANSFERRED=P,WMESSAGE=P,WRITE=M,WRITEBYTE=M,WRITELINE=M|' +
    'QSPLITTER:ALIGN=P,BEVELED=P,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,CURSOR=P,ENABLED=P,FONT=M,HANDLE=P,HEIGHT=P,HIDE=M,HINT=P,LEFT=P,MINSIZE=P,ONMOVED=E,PARENT=P,POPUPMENU=P,REPAINT=M' +
    ',SETFOCUS=M,SHOW=M,SHOWHINT=P,TABORDER=P,TAG=P,TOP=P,VISIBLE=P,WIDTH=P|' +
    'QSTATUSBAR:ADDPANELS=M,ALIGN=P,CLEAR=M,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,CURSOR=P,ENABLED=P,FONT=M,HANDLE=P,HEIGHT=P,HIDE=M,HINT=P,LEFT=P,ONRESIZE=E,PANEL=P,PANELCOUNT=P,PARENT=' +
    'P,POPUPMENU=P,REPAINT=M,SETFOCUS=M,SHOW=M,SHOWHINT=P,SIMPLEPANEL=P,SIMPLETEXT=P,SIZEGRIP=P,STRCALL=M,TABORDER=P,TAG=P,TOP=P,VISIBLE=P,WIDTH=P|' +
    'QSTATUSPANEL:ALIGNMENT=P,CAPTION=P,WIDTH=P|' +
    'QSTRINGGRID:ADDOPTIONS=M,ALIGN=P,BORDERSTYLE=P,CELL=P,CIRCLE=M,CLIENTHEIGHT=P,CLIENTWIDTH=P,COL=P,COLCOUNT=P,COLOR=P,COLUMNLIST=P,COLUMNSTYLE=P,COLWIDTHS=P,COPYRECT=M,COPYRECTPTR=M' +
    ',CURSOR=P,DEFAULTCOLWIDTH=P,DEFAULTROWHEIGHT=P,DELETECOL=M,DELETEROW=M,DELOPTIONS=M,DRAW=M,EDITORMODE=P,ENABLED=P,FILLRECT=M,FIXEDCOLOR=P,FIXEDCOLS=P,FIXEDROWS=P,FONT=P,GRIDHEIGHT=' +
    'P,GRIDLINEWIDTH=P,GRIDWIDTH=P,HANDLE=P,HEIGHT=P,HIDE=M,HINT=P,INSERTCOL=M,INSERTROW=M,LEFT=P,LEFTCOL=P,LINE=M,LOADFROMFILE=M,LOADFROMSTREAM=M,ONDRAWCELL=E,ONELLIPSISCLICK=E,ONKEYDO' +
    'WN=E,ONKEYPRESS=E,ONKEYUP=E,ONLISTDROPDOWN=E,ONMOUSEDOWN=E,ONMOUSEMOVE=E,ONMOUSEUP=E,ONSELECTCELL=E,ONSETEDITTEXT=E,PAINT=M,PARENT=P,POPUPMENU=P,PSET=M,RECTANGLE=M,REPAINT=M,ROUNDR' +
    'ECT=M,ROW=P,ROWCOUNT=P,ROWHEIGHTS=P,SAVETOFILE=M,SAVETOSTREAM=M,SCROLLBARS=P,SEPARATOR=P,SETCELL=M,SETFOCUS=M,SHOW=M,SHOWHINT=P,STRETCHDRAW=M,SWAPCOLS=M,SWAPROWS=M,TABORDER=P,TABST' +
    'OPS=P,TAG=P,TEXTHEIGHT=M,TEXTOUT=M,TEXTRECT=M,TEXTWIDTH=M,TOP=P,TOPROW=P,VISIBLE=P,VISIBLECOLCOUNT=P,VISIBLEROWCOUNT=P,WIDTH=P|' +
    'QSTRINGLIST:ADDITEMS=M,ADDLIST=M,BUILD=M,CLEAR=M,DELITEMS=M,DUPLICATES=P,EXCHANGE=M,FIND=M,INDEXOF=M,INSERTITEM=M,ITEM=P,ITEMCOUNT=P,LOADFROMFILE=M,LOADFROMSTREAM=M,PARSE=M,SAVETOF' +
    'ILE=M,SAVETOSTREAM=M,SORT=M,SORTED=P,TEXT=P|' +
    'QTABCONTROL:ADDTABS=M,ALIGN=P,BUTTONSTYLE=P,CLEAR=M,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,CURSOR=P,DELETETABS=M,DELTABS=M,ENABLED=P,FLATBUTTONS=P,FLATSEPERATORS=P,FOCUSBUTTONS=P,FON' +
    'T=P,HANDLE=P,HEIGHT=P,HIDE=M,HINT=P,HOTTRACK=P,INSERTTAB=M,LEFT=P,MULTILINE=P,ONCHANGE=E,ONMOUSEDOWN=E,ONMOUSEMOVE=E,ONMOUSEUP=E,PARENT=P,POPUPMENU=P,REPAINT=M,SCROLLOPPOSITE=P,SET' +
    'FOCUS=M,SHOW=M,SHOWHINT=P,STRCALL=M,TAB=P,TABCOUNT=P,TABHEIGHT=P,TABINACTIVECOLOR=P,TABINACTIVEFONT=P,TABINDEX=P,TABORDER=P,TABPOSITION=P,TABWIDTH=P,TAG=P,TOP=P,VERTICALTABS=P,VISI' +
    'BLE=P,WIDTH=P|' +
    'QTABCONTROLEX:|' +
    'QTIMER:ENABLED=P,INTERVAL=P,ONTIMER=E,RESTART=M,TAG=P|' +
    'QTRACKBAR:ALIGN=P,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLOR=P,CURSOR=P,ENABLED=P,FONT=M,FREQUENCY=P,HANDLE=P,HEIGHT=P,HIDE=M,HINT=P,LEFT=P,LINESIZE=P,MAX=P,MIN=P,ONCHANGE=E,ORIENTATION=P,' +
    'PAGESIZE=P,PARENT=P,POPUPMENU=P,POSITION=P,REPAINT=M,SELEND=P,SELSTART=P,SETFOCUS=M,SETTICK=M,SHOW=M,SHOWHINT=P,TABORDER=P,TAG=P,TICKMARKS=P,TICKSTYLE=P,TOP=P,VISIBLE=P,WIDTH=P|' +
    'QTREENODE:COUNT=P,HANDLE=P,HASCHILDREN=P,IMAGEINDEX=P,ISVISIBLE=P,LEVEL=P,PARENT=P,SELECTED=P,SELECTEDINDEX=P,STATEINDEX=P,TEXT=P|' +
    'QTREEVIEW:ADDCHILDITEMS=M,ADDITEMS=M,ALIGN=P,BORDERSTYLE=P,CLEAR=M,CLIENTHEIGHT=P,CLIENTWIDTH=P,COLLAPSE=M,COLOR=P,CURSOR=P,DELITEMS=M,ENABLED=P,EXPAND=M,FONT=P,FULLCOLLAPSE=M,FULL' +
    'EXPAND=M,GETITEMAT=M,HANDLE=P,HEIGHT=P,HIDE=M,HIDESELECTION=P,HINT=P,IMAGES=P,INDENT=P,INSERTITEM=M,ITEM=P,ITEMCOUNT=P,ITEMINDEX=P,LEFT=P,LOADFROMFILE=M,ONCHANGE=E,ONCHANGING=E,ONC' +
    'LICK=E,ONCOLLAPSE=E,ONCOLLAPSING=E,ONDBLCLICK=E,ONDELETION=E,ONEDITED=E,ONEDITING=E,ONEXPAND=E,ONEXPANDING=E,ONGETIMAGEINDEX=E,ONGETSELECTEDINDEX=E,ONKEYDOWN=E,ONKEYPRESS=E,ONKEYUP' +
    '=E,ONMOUSEDOWN=E,ONMOUSEMOVE=E,ONMOUSEUP=E,PARENT=P,POPUPMENU=P,READONLY=P,REPAINT=M,SAVETOFILE=M,SETFOCUS=M,SHOW=M,SHOWBUTTONS=P,SHOWHINT=P,SHOWLINES=P,SHOWROOT=P,SORT=M,SORTTYPE=' +
    'P,STATEIMAGES=P,STRCALL=M,TABORDER=P,TAG=P,TOP=P,TOPINDEX=P,VISIBLE=P,WIDTH=P|' +
    'RAPID:|';
// --- rqmembers: конец

// RqClassMembersText -> список 'КЛАСС.ИМЯ=вид' (отсортирован)
procedure FillClassMembers(AList: TStringList);
var
  ClassText, ClassName, Item: string;
  SepPos, ColonPos: Integer;
  Rest, Items: string;
begin
  Rest := RqClassMembersText;
  while Rest <> '' do
  begin
    SepPos := Pos('|', Rest);
    if SepPos = 0 then
      SepPos := Length(Rest) + 1;
    ClassText := Copy(Rest, 1, SepPos - 1);
    Delete(Rest, 1, SepPos);
    ColonPos := Pos(':', ClassText);
    if ColonPos = 0 then
      Continue;
    ClassName := Copy(ClassText, 1, ColonPos - 1);
    Items := Copy(ClassText, ColonPos + 1, MaxInt) + ',';
    while Items <> '' do
    begin
      SepPos := Pos(',', Items);
      Item := Copy(Items, 1, SepPos - 1);
      Delete(Items, 1, SepPos);
      if Item <> '' then
        AList.Add(ClassName + '.' + Item);
    end;
  end;
  AList.Sorted := True;
end;

constructor TRqFbConv.Create(const AOptions: TRqFbOptions; AMessages: TStrings);
var
  ClassIdx: Integer;
  MemberText: string;
begin
  inherited Create;
  FOpt := AOptions;
  FMsgs := AMessages;
  FVars := TStringList.Create;
  FVars.Sorted := True;
  FProcs := TStringList.Create;
  FProcs.Sorted := True;
  FTypes := TStringList.Create;
  FTypes.Sorted := True;
  FTypes.Duplicates := dupIgnore;
  FLabels := TStringList.Create;
  FLabels.Sorted := True;
  FLabels.Duplicates := dupIgnore;
  FGosubSites := TStringList.Create;
  FRedims := TStringList.Create;
  FRedims.Sorted := True;
  FRedims.Duplicates := dupIgnore;
  FDefines := TStringList.Create;
  FResources := TStringList.Create;
  FDoneFiles := TStringList.Create;
  FOutNames := TStringList.Create;
  FWarnedNames := TStringList.Create;
  FWarnedNames.Sorted := True;
  FKeywords := TStringList.Create;
  FillWordList(FKeywords, RqKeywordText);
  FFbStrFuncs := TStringList.Create;
  FillWordList(FFbStrFuncs, FbStrFuncText);
  FRqStrFuncs := TStringList.Create;
  FillWordList(FRqStrFuncs, RqOnlyStrFuncText);
  FFbReserved := TStringList.Create;
  FillWordList(FFbReserved, FbReservedText);
  FObjClasses := TStringList.Create;
  FillWordList(FObjClasses, RqObjectText);
  FGuiClasses := TStringList.Create;
  FillWordList(FGuiClasses, RqGuiObjectText);
  FFuncMap := TStringList.Create;
  FFuncMap.Text := StringReplace(RqFuncMapText, ' ', CrLf, [rfReplaceAll]);
  FEventSigs := TStringList.Create;
  FEventSigs.Text := StringReplace(RqEventSigText, ' ', CrLf, [rfReplaceAll]);
  FHandlerEvents := TStringList.Create;
  FHandlerProcs := TStringList.Create;
  FBinds := TStringList.Create;
  FHandlerProcs.Sorted := True;
  FHandlerProcs.Duplicates := dupIgnore;
  FCreateStack := TStringList.Create;
  FClassMembers := TStringList.Create;
  FillClassMembers(FClassMembers);
  FAllMembers := TStringList.Create;
  for ClassIdx := 0 to FClassMembers.Count - 1 do
  begin
    MemberText := FClassMembers[ClassIdx];
    MemberText := Copy(MemberText, Pos('.', MemberText) + 1, MaxInt);
    if FAllMembers.IndexOfName(Copy(MemberText, 1, Pos('=', MemberText) - 1)) < 0 then
      FAllMembers.Add(MemberText)
    else if Copy(MemberText, Length(MemberText), 1) = 'P' then
      // свойство важнее метода с тем же именем
      FAllMembers.Values[Copy(MemberText, 1, Pos('=', MemberText) - 1)] := 'P';
  end;
  FAllMembers.Sorted := True;
  FIndexedSet := TStringList.Create;
  FIndexedSet.Text := StringReplace(RqIndexedSetText, ' ', CrLf, [rfReplaceAll]);
  FMemberMap := TStringList.Create;
  FMemberMap.Text := StringReplace(RqMemberMapText, ' ', CrLf, [rfReplaceAll]);
  FTypeInfos := TStringList.Create;
  FTypeInfos.Sorted := True;
  FBadMembers := TStringList.Create;
  FillWordList(FBadMembers, FbBadMemberText);
  // Глобальные объекты RapidQ - объявлены в rqlcl.bi (rqsys.bi) и rqrt.bi
  DeclareVar('Application', 'QAPPLICATION', '', False, True, False);
  DeclareVar('Screen', 'QSCREEN', '', False, True, False);
  DeclareVar('Clipboard', 'QCLIPBOARD', '', False, True, False);
  DeclareVar('Printer', 'QPRINTER', '', False, True, False);
  DeclareVar('FileRec', 'RQFILERECTYPE', '', False, True, False);
end;

destructor TRqFbConv.Destroy;
var
  ItemIdx: Integer;
begin
  for ItemIdx := 0 to FVars.Count - 1 do
    FVars.Objects[ItemIdx].Free;
  for ItemIdx := 0 to FProcs.Count - 1 do
    FProcs.Objects[ItemIdx].Free;
  FVars.Free;
  FProcs.Free;
  FTypes.Free;
  FLabels.Free;
  FGosubSites.Free;
  FRedims.Free;
  FDefines.Free;
  FResources.Free;
  FDoneFiles.Free;
  FOutNames.Free;
  FWarnedNames.Free;
  FKeywords.Free;
  FFbStrFuncs.Free;
  FRqStrFuncs.Free;
  FFbReserved.Free;
  FObjClasses.Free;
  FGuiClasses.Free;
  FFuncMap.Free;
  FMemberMap.Free;
  FIndexedSet.Free;
  FEventSigs.Free;
  FHandlerEvents.Free;
  FHandlerProcs.Free;
  FBinds.Free;
  FCreateStack.Free;
  FClassMembers.Free;
  FAllMembers.Free;
  for ItemIdx := 0 to FTypeInfos.Count - 1 do
    FTypeInfos.Objects[ItemIdx].Free;
  FTypeInfos.Free;
  FBadMembers.Free;
  inherited Destroy;
end;

procedure TRqFbConv.Msg(const ALevel, AText: string);
begin
  if FPass <> 2 then
    Exit;
  if FMsgs <> nil then
    FMsgs.Add(FCurFile + '(' + IntToStr(FCurLine) + ') ' + ALevel + ': ' +
              AText);
end;

procedure TRqFbConv.Warn(const AText: string);
begin
  if FPass = 2 then
    Inc(FWarnings);
  Msg('Warning', AText);
end;

procedure TRqFbConv.Error(const AText: string);
begin
  if FPass = 2 then
    Inc(FErrors);
  Msg('Error', AText);
end;

// Предупреждение один раз на программу по ключу AKey
procedure TRqFbConv.WarnOnce(const AKey, AText: string);
var
  Found: Integer;
begin
  if FPass <> 2 then
    Exit;
  if FWarnedNames.Find(AKey, Found) then
    Exit;
  FWarnedNames.Add(AKey);
  Warn(AText);
end;

function TRqFbConv.CondActive: Boolean;
begin
  Result := (Length(FConds) = 0) or FConds[High(FConds)].Active;
end;

// ---------------------------------------------------------------------------
//  Лексер: слова (с суффиксом типа), числа, строки, комментарии,
//  директивы ($INCLUDE, #define), знаки. Пробелы и переводы строк
//  (продолжение " _") - отдельные лексемы: вывод повторяет исходник.
// ---------------------------------------------------------------------------

procedure TRqFbConv.Lex(const AText: string; var AToks: TToks);
var
  Pos0, Pos1, TextLen, Count: Integer;
  Ch: Char;

  procedure Add(AKind: TTokKind; AStart, AEnd: Integer);
  begin
    if Count >= Length(AToks) then
      SetLength(AToks, Count * 2 + 16);
    AToks[Count].Kind := AKind;
    AToks[Count].Text := Copy(AText, AStart, AEnd - AStart + 1);
    if AKind in [tkIdent, tkDirective] then
      AToks[Count].Up := UpperCase(AToks[Count].Text)
    else
      AToks[Count].Up := AToks[Count].Text;
    AToks[Count].OutText := AToks[Count].Text;
    AToks[Count].Pre := '';
    AToks[Count].Post := '';
    Inc(Count);
  end;

  function IsIdentStart(AChar: Char): Boolean;
  begin
    // ~ - в именах RapidQ (~SrcD, ~tmp$)
    Result := AChar in ['A'..'Z', 'a'..'z', '_', '~'];
  end;

  function IsIdentChar(AChar: Char): Boolean;
  begin
    Result := AChar in ['A'..'Z', 'a'..'z', '0'..'9', '_', '~'];
  end;

begin
  SetLength(AToks, 0);
  Count := 0;
  TextLen := Length(AText);
  Pos0 := 1;
  while Pos0 <= TextLen do
  begin
    Ch := AText[Pos0];
    Pos1 := Pos0;
    // Пробелы, табуляция, переводы строк, продолжение " _"
    if Ch in [' ', #9, #13, #10] then
    begin
      while (Pos1 + 1 <= TextLen) and (AText[Pos1 + 1] in [' ', #9, #13, #10]) do
        Inc(Pos1);
      Add(tkSpace, Pos0, Pos1);
    end
    else if (Ch = '_') and ((Pos0 = TextLen) or
            (AText[Pos0 + 1] in [' ', #9, #13, #10])) and
            ((Pos0 = 1) or not (AText[Pos0 - 1] in ['A'..'Z', 'a'..'z',
                                                    '0'..'9', '_'])) then
    begin
      // "_" продолжения со всем, что до конца физической строки
      while (Pos1 + 1 <= TextLen) and (AText[Pos1 + 1] in [' ', #9, #13, #10]) do
        Inc(Pos1);
      Add(tkSpace, Pos0, Pos1);
    end
    else if Ch = '''' then
    begin
      // Комментарий до конца строки (физической)
      while (Pos1 + 1 <= TextLen) and not (AText[Pos1 + 1] in [#13, #10]) do
        Inc(Pos1);
      Add(tkComment, Pos0, Pos1);
      // '$INCLUDE и ' $INCLUDE в комментарии fbc принимает за метакоманду
      // QBasic; ''$INCLUDE - обычный комментарий
      if Copy(TrimLeft(Copy(AToks[Count - 1].Text, 2, MaxInt)), 1, 1) = '$' then
        AToks[Count - 1].OutText := '''' + AToks[Count - 1].Text;
      // Комментарий после "_" внутри строки, собранной из продолжений: дальше
      // оператор идёт - это часть пробела (FreeBASIC после "_" тоже
      // пропускает всё до конца строки)
      if (Count >= 2) and (AToks[Count - 2].Kind = tkSpace) and
         (Copy(AToks[Count - 2].Text, 1, 1) = '_') and
         (Trim(Copy(AText, Pos1 + 1, MaxInt)) <> '') then
        AToks[Count - 1].Kind := tkSpace;
    end
    else if Ch = '"' then
    begin
      Inc(Pos1);
      while Pos1 <= TextLen do
      begin
        if FEscape and (AText[Pos1] = '\') and (Pos1 < TextLen) then
          Inc(Pos1, 2)
        else if AText[Pos1] = '"' then
          Break
        else
          Inc(Pos1);
      end;
      if Pos1 > TextLen then
        Pos1 := TextLen;
      Add(tkString, Pos0, Pos1);
    end
    else if ((Ch = '$') or (Ch = '#')) and (Pos0 < TextLen) and
            IsIdentStart(AText[Pos0 + 1]) and
            ((Count = 0) or ((Count = 1) and (AToks[0].Kind = tkSpace))) then
    begin
      // $INCLUDE, $DEFINE... в начале строки; #define - то же, что $DEFINE
      Inc(Pos1);
      while (Pos1 + 1 <= TextLen) and IsIdentChar(AText[Pos1 + 1]) do
        Inc(Pos1);
      Add(tkDirective, Pos0, Pos1);
      AToks[Count - 1].Up := '$' + Copy(AToks[Count - 1].Up, 2, MaxInt);
    end
    else if IsIdentStart(Ch) then
    begin
      while (Pos1 + 1 <= TextLen) and IsIdentChar(AText[Pos1 + 1]) do
        Inc(Pos1);
      // Суффикс типа: $ % & ! # ? ?? ???
      if (Pos1 + 1 <= TextLen) and (AText[Pos1 + 1] in ['$', '%', '!', '#']) then
        Inc(Pos1)
      else if (Pos1 + 1 <= TextLen) and (AText[Pos1 + 1] = '&') and
              not ((Pos1 + 2 <= TextLen) and
                   (UpCase(AText[Pos1 + 2]) in ['H', 'O', 'B'])) then
        Inc(Pos1)
      else if (Pos1 + 1 <= TextLen) and (AText[Pos1 + 1] = '?') then
      begin
        Inc(Pos1);
        if (Pos1 + 1 <= TextLen) and (AText[Pos1 + 1] = '?') then
          Inc(Pos1);
        if (Pos1 + 1 <= TextLen) and (AText[Pos1 + 1] = '?') then
          Inc(Pos1);
      end;
      Add(tkIdent, Pos0, Pos1);
    end
    else if (Ch in ['0'..'9']) or ((Ch = '.') and (Pos0 < TextLen) and
            (AText[Pos0 + 1] in ['0'..'9'])) then
    begin
      while (Pos1 + 1 <= TextLen) and (AText[Pos1 + 1] in ['0'..'9', '.']) do
        Inc(Pos1);
      if (Pos1 + 1 <= TextLen) and (UpCase(AText[Pos1 + 1]) in ['E', 'D']) and
         (Pos1 + 2 <= TextLen) and
         (AText[Pos1 + 2] in ['0'..'9', '+', '-']) then
      begin
        Inc(Pos1, 2);
        while (Pos1 + 1 <= TextLen) and (AText[Pos1 + 1] in ['0'..'9']) do
          Inc(Pos1);
      end;
      if (Pos1 + 1 <= TextLen) and (AText[Pos1 + 1] in ['!', '#', '%', '&']) then
        Inc(Pos1);
      Add(tkNumber, Pos0, Pos1);
    end
    else if (Ch = '&') and (Pos0 < TextLen) and
            (UpCase(AText[Pos0 + 1]) in ['H', 'O', 'B']) then
    begin
      Inc(Pos1);
      while (Pos1 + 1 <= TextLen) and
            (UpCase(AText[Pos1 + 1]) in ['0'..'9', 'A'..'F']) do
        Inc(Pos1);
      Add(tkNumber, Pos0, Pos1);
    end
    else
    begin
      if (Pos1 + 1 <= TextLen) and
         (((Ch = '<') and (AText[Pos1 + 1] in ['>', '='])) or
          ((Ch = '>') and (AText[Pos1 + 1] = '='))) then
        Inc(Pos1);
      Add(tkOp, Pos0, Pos1);
    end;
    Pos0 := Pos1 + 1;
  end;
  SetLength(AToks, Count);
end;

function TRqFbConv.NextSig(const AToks: TToks; AFrom, ATo: Integer): Integer;
var
  TokIdx: Integer;
begin
  Result := -1;
  if AFrom < 0 then
    Exit;
  for TokIdx := AFrom to ATo do
    if (TokIdx <= High(AToks)) and (AToks[TokIdx].Kind <> tkSpace) then
    begin
      Result := TokIdx;
      Exit;
    end;
end;

function TRqFbConv.PrevSig(const AToks: TToks; AFrom: Integer): Integer;
var
  TokIdx: Integer;
begin
  Result := -1;
  for TokIdx := AFrom downto 0 do
    if AToks[TokIdx].Kind <> tkSpace then
    begin
      Result := TokIdx;
      Exit;
    end;
end;

// Закрывающая скобка к открывающей AOpen; нет - -1
function TRqFbConv.MatchParen(const AToks: TToks; AOpen, ATo: Integer): Integer;
var
  TokIdx, Depth: Integer;
begin
  Result := -1;
  Depth := 0;
  for TokIdx := AOpen to ATo do
    if AToks[TokIdx].Kind = tkOp then
    begin
      if AToks[TokIdx].Text = '(' then
        Inc(Depth)
      else if AToks[TokIdx].Text = ')' then
      begin
        Dec(Depth);
        if Depth = 0 then
        begin
          Result := TokIdx;
          Exit;
        end;
      end;
    end;
end;

function TRqFbConv.IsOp(const AToks: TToks; AIdx: Integer; const AOp: string): Boolean;
begin
  Result := (AIdx >= 0) and (AIdx <= High(AToks)) and
            (AToks[AIdx].Kind = tkOp) and (AToks[AIdx].Text = AOp);
end;

function TRqFbConv.IsWord(const AToks: TToks; AIdx: Integer; const AWord: string): Boolean;
begin
  Result := (AIdx >= 0) and (AIdx <= High(AToks)) and
            (AToks[AIdx].Kind = tkIdent) and (AToks[AIdx].Up = AWord);
end;

// $DEFINE: слово заменяется определением (один раз, без повторной замены)
function TRqFbConv.ApplyDefines(const AText: string): string;
var
  Toks: TToks;
  TokIdx, PrevIdx, FirstIdx, DefIdx: Integer;
  FirstUp: string;
begin
  Result := AText;
  if FDefines.Count = 0 then
    Exit;
  Lex(AText, Toks);
  FirstIdx := NextSig(Toks, 0, High(Toks));
  FirstUp := '';
  if FirstIdx >= 0 then
    FirstUp := Toks[FirstIdx].Up;
  Result := '';
  for TokIdx := 0 to High(Toks) do
  begin
    if (Toks[TokIdx].Kind = tkIdent) and
       // в самих $DEFINE / $UNDEF / $IFDEF заменяется только первое слово
       not (((FirstUp = '$DEFINE') or (FirstUp = '$UNDEF') or
             (FirstUp = '$IFDEF') or (FirstUp = '$IFNDEF')) and
            (TokIdx > FirstIdx)) then
    begin
      PrevIdx := PrevSig(Toks, TokIdx - 1);
      if not IsOp(Toks, PrevIdx, '.') then
      begin
        DefIdx := FDefines.IndexOfName(Toks[TokIdx].Up);
        if DefIdx >= 0 then
        begin
          Result := Result + FDefines.ValueFromIndex[DefIdx];
          Continue;
        end;
      end;
    end;
    Result := Result + Toks[TokIdx].Text;
  end;
end;

// Текст вывода лексем AFrom..ATo в одну строку: переводы строк -
// пробелами, их число - в FLostLines (Rebuild вернёт их продолжениями)
function TRqFbConv.RangeText(const AToks: TToks; AFrom, ATo: Integer): string;
var
  TokIdx: Integer;
begin
  Result := '';
  for TokIdx := AFrom to ATo do
  begin
    if AToks[TokIdx].Kind = tkSpace then
    begin
      Inc(FLostLines, CountLineBreaks(AToks[TokIdx].OutText));
      if AToks[TokIdx].OutText <> '' then
        Result := Result + ' ';
    end
    else
      Result := Result + AToks[TokIdx].Pre + AToks[TokIdx].OutText +
                AToks[TokIdx].Post;
  end;
  Result := Trim(Result);
end;

// Исходный текст лексем (для сообщений)
function TRqFbConv.RawText(const AToks: TToks; AFrom, ATo: Integer): string;
var
  TokIdx: Integer;
begin
  Result := '';
  for TokIdx := AFrom to ATo do
    if AToks[TokIdx].Kind = tkSpace then
      Result := Result + ' '
    else
      Result := Result + AToks[TokIdx].Text;
  Result := Trim(Result);
end;

procedure TRqFbConv.ClearRange(var AToks: TToks; AFrom, ATo: Integer);
var
  TokIdx: Integer;
begin
  for TokIdx := AFrom to ATo do
  begin
    if AToks[TokIdx].Kind = tkSpace then
      Inc(FLostLines, CountLineBreaks(AToks[TokIdx].OutText));
    AToks[TokIdx].OutText := '';
    AToks[TokIdx].Pre := '';
    AToks[TokIdx].Post := '';
  end;
end;

// Оператор AFrom..ATo заменяется текстом AText; переводы строк, которые
// в нём были, - продолжениями " _" в конце (число строк не меняется)
procedure TRqFbConv.Rebuild(var AToks: TToks; AFrom, ATo: Integer; const AText: string);
var
  FirstIdx: Integer;
begin
  ClearRange(AToks, AFrom, ATo);
  FirstIdx := NextSig(AToks, AFrom, ATo);
  if FirstIdx < 0 then
    FirstIdx := AFrom;
  AToks[FirstIdx].OutText := AText + RepeatText(ContinueMark, FLostLines);
  FLostLines := 0;
end;

// Строки текста - комментариями (число строк то же)
function TRqFbConv.CommentOut(const AText: string): string;
begin
  Result := '''~ ' + StringReplace(AText, #10, #10 + '''~ ', [rfReplaceAll]);
end;

// ---------------------------------------------------------------------------
//  Имена и типы
// ---------------------------------------------------------------------------

function TRqFbConv.SuffixOf(const AName: string): string;
var
  CharIdx: Integer;
begin
  CharIdx := Length(AName);
  while (CharIdx > 0) and (AName[CharIdx] in ['$', '%', '&', '!', '#', '?']) do
    Dec(CharIdx);
  Result := Copy(AName, CharIdx + 1, MaxInt);
end;

function TRqFbConv.BaseOf(const AName: string): string;
begin
  Result := Copy(AName, 1, Length(AName) - Length(SuffixOf(AName)));
end;

function TRqFbConv.SuffixType(const ASuffix: string): string;
begin
  if ASuffix = '$' then
    Result := 'STRING'
  else if ASuffix = '%' then
    Result := 'SHORT'
  else if ASuffix = '&' then
    Result := 'LONG'
  else if ASuffix = '!' then
    Result := 'SINGLE'
  else if ASuffix = '#' then
    Result := 'DOUBLE'
  else if ASuffix = '?' then
    Result := 'BYTE'
  else if ASuffix = '??' then
    Result := 'WORD'
  else if ASuffix = '???' then
    Result := 'DWORD'
  else
    Result := FDefaultType;
end;

// Имя для FreeBASIC: суффикс - частью имени (a$ -> a__s), слово
// FreeBASIC - с _v
function TRqFbConv.Mangle(const ADisplay: string): string;
var
  Suffix, Base: string;
begin
  Suffix := SuffixOf(ADisplay);
  Base := BaseOf(ADisplay);
  if Suffix = '$' then
    Result := Base + '__s'
  else if Suffix = '%' then
    Result := Base + '__sh'
  else if Suffix = '&' then
    Result := Base + '__l'
  else if Suffix = '!' then
    Result := Base + '__f'
  else if Suffix = '#' then
    Result := Base + '__d'
  else if Suffix = '?' then
    Result := Base + '__b'
  else if Suffix = '??' then
    Result := Base + '__w'
  else if Suffix = '???' then
    Result := Base + '__dw'
  else if InList(FFbReserved, UpperCase(Base)) then
    Result := Base + '_v'
  else
    Result := Base;
  // ~ в имени RapidQ: в FreeBASIC нельзя -> _T_ (~SrcD -> _T_SrcD)
  if Pos('~', Result) > 0 then
    Result := StringReplace(Result, '~', '_T_', [rfReplaceAll]);
end;

function TRqFbConv.NormType(const AUp: string): string;
begin
  if AUp = 'INTEGER' then
    Result := 'LONG'
  else
    Result := AUp;
end;

function TRqFbConv.FbType(const ARqType: string): string;
begin
  if ARqType = 'DOUBLE' then
    Result := 'Double'
  else if ARqType = 'SINGLE' then
    Result := 'Single'
  else if ARqType = 'LONG' then
    Result := 'Long'
  else if ARqType = 'SHORT' then
    Result := 'Short'
  else if ARqType = 'BYTE' then
    Result := 'UByte'
  else if ARqType = 'WORD' then
    Result := 'UShort'
  else if ARqType = 'DWORD' then
    Result := 'ULong'
  else if ARqType = 'STRING' then
    Result := 'String'
  else
    Result := ARqType;
end;

function TRqFbConv.ConvFunc(const ARqType: string): string;
begin
  if ARqType = 'DOUBLE' then
    Result := 'RqNum'
  else if ARqType = 'SINGLE' then
    Result := 'RqSng'
  else if ARqType = 'LONG' then
    Result := 'RqLong'
  else if ARqType = 'SHORT' then
    Result := 'RqShort'
  else if ARqType = 'BYTE' then
    Result := 'RqByte'
  else if ARqType = 'WORD' then
    Result := 'RqWord'
  else if ARqType = 'DWORD' then
    Result := 'RqDword'
  else if ARqType = 'STRING' then
    Result := 'RqStr'
  else
    Result := '';
end;

function TRqFbConv.IsObjectType(const ARqType: string): Boolean;
begin
  Result := InList(FObjClasses, ARqType) or InList(FTypes, ARqType) or
            (ARqType = 'VARIANT');
end;

function TRqFbConv.IsNumericType(const ARqType: string): Boolean;
begin
  Result := (ARqType <> 'STRING') and (ConvFunc(ARqType) <> '');
end;

// Тип после AS (AIdx - на слове типа; после разбора - на последней
// лексеме типа). STRING * n - длина в AStarLen.
function TRqFbConv.ParseType(const AToks: TToks; var AIdx: Integer; ATo: Integer;
                             var AStarLen: string): string;
var
  StarIdx, LenIdx: Integer;
begin
  AStarLen := '';
  Result := NormType(AToks[AIdx].Up);
  if Result = 'STRING' then
  begin
    StarIdx := NextSig(AToks, AIdx + 1, ATo);
    if IsOp(AToks, StarIdx, '*') then
    begin
      LenIdx := NextSig(AToks, StarIdx + 1, ATo);
      if LenIdx >= 0 then
      begin
        AStarLen := AToks[LenIdx].Text;
        AIdx := LenIdx;
      end;
    end;
  end;
  if Result = 'VARIANT' then
    WarnOnce('VARIANT', 'тип VARIANT пока не поддержан');
end;

// Переменная по имени: сначала в текущей SUB/FUNCTION, потом в модуле
function TRqFbConv.FindVar(const AUp: string): TRqVar;
var
  Found: Integer;
begin
  Result := nil;
  if (FCurProc <> nil) and FVars.Find(FCurProc.Name + '|' + AUp, Found) then
  begin
    Result := TRqVar(FVars.Objects[Found]);
    Exit;
  end;
  if FVars.Find('|' + AUp, Found) then
    Result := TRqVar(FVars.Objects[Found]);
end;

function TRqFbConv.DeclareVar(const ADisplay, ARqType, AScope: string;
                              AIsArray, AExplicit, AIsConst: Boolean): TRqVar;
var
  Key: string;
  Found: Integer;
begin
  Key := AScope + '|' + UpperCase(ADisplay);
  if FVars.Find(Key, Found) then
  begin
    Result := TRqVar(FVars.Objects[Found]);
    if AExplicit then
    begin
      Result.Explicit := True;
      Result.RqType := ARqType;
      Result.IsArray := Result.IsArray or AIsArray;
      Result.IsConst := AIsConst;
    end;
    Exit;
  end;
  Result := TRqVar.Create;
  Result.Name := UpperCase(ADisplay);
  Result.FbName := Mangle(ADisplay);
  // Параметр или локальная с именем константы модуля: в RapidQ она
  // перекрывает константу, в FreeBASIC - ошибка "Duplicated definition"
  // (rapidq.inc: CONST clR и параметр Clr)
  if (AScope <> '') and FVars.Find('|' + UpperCase(ADisplay), Found) and
     TRqVar(FVars.Objects[Found]).IsConst then
    Result.FbName := Result.FbName + '_p';
  Result.RqType := ARqType;
  Result.Scope := AScope;
  Result.IsArray := AIsArray;
  Result.Explicit := AExplicit;
  Result.IsConst := AIsConst;
  FVars.AddObject(Key, Result);
end;

// Пара для '[' (s$[N]); нет - -1
function TRqFbConv.MatchBracket(const AToks: TToks; AOpen, ATo: Integer): Integer;
var
  TokIdx, Depth: Integer;
begin
  Result := -1;
  Depth := 0;
  for TokIdx := AOpen to ATo do
    if AToks[TokIdx].Kind = tkOp then
    begin
      if AToks[TokIdx].Text = '[' then
        Inc(Depth)
      else if AToks[TokIdx].Text = ']' then
      begin
        Dec(Depth);
        if Depth = 0 then
        begin
          Result := TokIdx;
          Exit;
        end;
      end;
    end;
end;

// s$[N] - символ строки с 1; вне строки (0, за концом) - "" (тест в
// RapidQ 2026-10-08: "123456"[0] -> "", [1] -> "1", [8] -> ""):
// s$[N] -> RqStrIdx(s$, N). Только чтение.
procedure TRqFbConv.WrapStrIndex(var AToks: TToks; AIdx, ATo: Integer; AVar: TRqVar);
var
  OpenIdx, CloseIdx, InsPos: Integer;
  PreText: string;
begin
  if (AVar = nil) or AVar.IsArray or
     ((UpperCase(AVar.RqType) <> 'STRING') and (SuffixOf(AVar.Name) <> '$')) then
    Exit;
  OpenIdx := NextSig(AToks, AIdx + 1, ATo);
  if not IsOp(AToks, OpenIdx, '[') then
    Exit;
  CloseIdx := MatchBracket(AToks, OpenIdx, ATo);
  if CloseIdx < 0 then
    Exit;
  // RqStrSub( из RewriteStrSub - снаружи
  PreText := AToks[AIdx].Pre;
  InsPos := 1;
  while Copy(PreText, InsPos, 9) = 'RqStrSub(' do
    Inc(InsPos, 9);
  Insert('RqStrIdx(', PreText, InsPos);
  AToks[AIdx].Pre := PreText;
  AToks[OpenIdx].OutText := ', ';
  AToks[CloseIdx].OutText := ')';
end;

// Вычитание строк RapidQ: "jello" - "l" -> "jeo" (все вхождения;
// документация, operators.html). В цепочке + - & одного уровня скобок, где
// есть строка, a - b -> RqStrSub(a, b): a + b - c -> RqStrSub(a + b, c).
procedure TRqFbConv.RewriteStrSub(var AToks: TToks; AFrom, ATo: Integer);
var
  TokIdx, ChainStart, CloseIdx: Integer;
  IsDelim: Boolean;
begin
  ChainStart := -1;
  TokIdx := AFrom;
  while TokIdx <= ATo do
  begin
    if AToks[TokIdx].Kind in [tkSpace, tkComment] then
    begin
      Inc(TokIdx);
      Continue;
    end;
    if IsOp(AToks, TokIdx, '(') or IsOp(AToks, TokIdx, '[') then
    begin
      if IsOp(AToks, TokIdx, '(') then
        CloseIdx := MatchParen(AToks, TokIdx, ATo)
      else
        CloseIdx := MatchBracket(AToks, TokIdx, ATo);
      if CloseIdx < 0 then
        CloseIdx := ATo;
      if ChainStart < 0 then
        ChainStart := TokIdx;
      RewriteStrSub(AToks, TokIdx + 1, CloseIdx - 1);
      TokIdx := CloseIdx + 1;
      Continue;
    end;
    IsDelim := False;
    if AToks[TokIdx].Kind = tkOp then
      IsDelim := Pos(' ' + AToks[TokIdx].Text + ' ', ' , ; = < > <> <= >= : ) ] ') > 0
    else if AToks[TokIdx].Kind = tkIdent then
      IsDelim := Pos(' ' + AToks[TokIdx].Up + ' ',
        ' AND OR XOR NOT THEN ELSE TO STEP ANDALSO ORELSE IMP EQV ') > 0;
    if IsDelim then
    begin
      if ChainStart >= 0 then
        FinishStrSub(AToks, ChainStart, PrevSig(AToks, TokIdx - 1));
      ChainStart := -1;
    end
    else if ChainStart < 0 then
      ChainStart := TokIdx;
    Inc(TokIdx);
  end;
  if ChainStart >= 0 then
    FinishStrSub(AToks, ChainStart, PrevSig(AToks, ATo));
end;

procedure TRqFbConv.FinishStrSub(var AToks: TToks; AFrom, ATo: Integer);
var
  TokIdx, PrevIdx, OperandStart, CloseIdx, MinusCount, OpIdx: Integer;
  Ops: array of Integer;   // бинарные + - & цепочки
  HasString: Boolean;
  PrefixText: string;
begin
  if (AFrom < 0) or (ATo < AFrom) then
    Exit;
  SetLength(Ops, 0);
  MinusCount := 0;
  TokIdx := AFrom;
  while TokIdx <= ATo do
  begin
    if IsOp(AToks, TokIdx, '(') or IsOp(AToks, TokIdx, '[') then
    begin
      if IsOp(AToks, TokIdx, '(') then
        CloseIdx := MatchParen(AToks, TokIdx, ATo)
      else
        CloseIdx := MatchBracket(AToks, TokIdx, ATo);
      if CloseIdx < 0 then
        Exit;
      TokIdx := CloseIdx + 1;
      Continue;
    end;
    if (AToks[TokIdx].Kind = tkOp) and
       ((AToks[TokIdx].Text = '+') or (AToks[TokIdx].Text = '-') or
        (AToks[TokIdx].Text = '&')) then
    begin
      // бинарный - слева конец операнда; уже переписанный '-' - пропустить
      PrevIdx := PrevSig(AToks, TokIdx - 1);
      if (PrevIdx >= AFrom) and
         ((AToks[PrevIdx].Kind in [tkIdent, tkNumber, tkString]) or
          IsOp(AToks, PrevIdx, ')') or IsOp(AToks, PrevIdx, ']')) then
      begin
        if (AToks[TokIdx].Text = '-') and (AToks[TokIdx].OutText <> '-') then
          Exit;
        SetLength(Ops, Length(Ops) + 1);
        Ops[High(Ops)] := TokIdx;
        if AToks[TokIdx].Text = '-' then
          Inc(MinusCount);
      end;
    end;
    Inc(TokIdx);
  end;
  if MinusCount = 0 then
    Exit;
  // есть ли строка среди операндов
  HasString := False;
  OperandStart := AFrom;
  for OpIdx := 0 to High(Ops) + 1 do
  begin
    if OpIdx <= High(Ops) then
      TokIdx := Ops[OpIdx] - 1
    else
      TokIdx := ATo;
    if ExprIsString(AToks, OperandStart, TokIdx) then
      HasString := True;
    if OpIdx <= High(Ops) then
      OperandStart := Ops[OpIdx] + 1;
  end;
  if not HasString then
    Exit;
  PrefixText := '';
  for OpIdx := 1 to MinusCount do
    PrefixText := PrefixText + 'RqStrSub(';
  TokIdx := NextSig(AToks, AFrom, ATo);
  AToks[TokIdx].Pre := PrefixText + AToks[TokIdx].Pre;
  for OpIdx := 0 to High(Ops) do
    if AToks[Ops[OpIdx]].Text = '-' then
    begin
      AToks[Ops[OpIdx]].OutText := ',';
      // ')' - после правого операнда
      if OpIdx < High(Ops) then
        TokIdx := PrevSig(AToks, Ops[OpIdx + 1] - 1)
      else
        TokIdx := ATo;
      AToks[TokIdx].Post := AToks[TokIdx].Post + ')';
    end;
end;

// Перем ++ (оператор RapidQ, loops.html: I++) -> Перем += 1
function TRqFbConv.ProcessPlusPlus(var AToks: TToks; AFirst, ATo: Integer): Boolean;
var
  LastIdx, PlusIdx, TargetEnd: Integer;
  VarRec: TRqVar;
begin
  Result := False;
  LastIdx := PrevSig(AToks, ATo);
  if not IsOp(AToks, LastIdx, '+') then
    Exit;
  PlusIdx := PrevSig(AToks, LastIdx - 1);
  if not IsOp(AToks, PlusIdx, '+') or (PlusIdx <= AFirst) then
    Exit;
  TargetEnd := PrevSig(AToks, PlusIdx - 1);
  if not ((AToks[TargetEnd].Kind = tkIdent) or IsOp(AToks, TargetEnd, ')')) then
    Exit;
  ProcessExpr(AToks, AFirst, TargetEnd);
  VarRec := FindVar(AToks[AFirst].Up);
  if VarRec <> nil then
    VarRec.Assigned := True;
  AToks[PlusIdx].OutText := '+= 1';
  AToks[LastIdx].OutText := '';
  if PlusIdx + 1 < LastIdx then
    ClearRange(AToks, PlusIdx + 1, LastIdx - 1);
  if AToks[PlusIdx - 1].Kind <> tkSpace then
    AToks[PlusIdx].Pre := ' ' + AToks[PlusIdx].Pre;
  Result := True;
end;

// Значение необъявленной переменной в тексте предупреждения
function TRqFbConv.DefaultValueText(const ARqType: string): string;
begin
  if UpperCase(ARqType) = 'STRING' then
    Result := '""'
  else
    Result := '0';
end;

// Переменная из выражения; не объявлена - неявная (тип по суффиксу)
function TRqFbConv.ResolveVar(const ADisplay: string; AIsArray: Boolean): TRqVar;
var
  Scope: string;
begin
  Result := FindVar(UpperCase(ADisplay));
  if Result = nil then
  begin
    Scope := '';
    if FCurProc <> nil then
      Scope := FCurProc.Name;
    Result := DeclareVar(ADisplay, SuffixType(SuffixOf(ADisplay)), Scope,
                         AIsArray, False, False);
    if AIsArray then
      WarnOnce('ARR|' + UpperCase(ADisplay), ADisplay + ': массив без DIM');
  end;
  if (FPass = 2) and FTypeCheck and not Result.Explicit then
    Error(ADisplay + ': переменная не объявлена ($TYPECHECK ON)');
end;

function TRqFbConv.FindProc(const AUp: string): TRqProc;
var
  Found: Integer;
begin
  Result := nil;
  if FProcs.Find(AUp, Found) then
    Result := TRqProc(FProcs.Objects[Found]);
end;

function TRqFbConv.GetProc(const ADisplay: string): TRqProc;
begin
  Result := FindProc(UpperCase(ADisplay));
  if Result <> nil then
    Exit;
  Result := TRqProc.Create;
  Result.Name := UpperCase(ADisplay);
  Result.FbName := Mangle(ADisplay);
  FProcs.AddObject(Result.Name, Result);
end;

// Выражение - строковое: на верхнем уровне скобок есть строка в кавычках,
// строковая переменная или функция со знаком $
function TRqFbConv.ExprIsString(const AToks: TToks; AFrom, ATo: Integer): Boolean;
var
  TokIdx, Depth: Integer;
  VarRec: TRqVar;
  ProcRec: TRqProc;
begin
  Result := False;
  Depth := 0;
  for TokIdx := AFrom to ATo do
  begin
    if IsOp(AToks, TokIdx, '(') then
      Inc(Depth)
    else if IsOp(AToks, TokIdx, ')') then
      Dec(Depth)
    else if Depth = 0 then
    begin
      if AToks[TokIdx].Kind = tkString then
        Result := True
      else if (AToks[TokIdx].Kind = tkIdent) and
              not IsOp(AToks, PrevSig(AToks, TokIdx - 1), '.') then
      begin
        if SuffixOf(AToks[TokIdx].Up) = '$' then
          Result := True
        else
        begin
          VarRec := FindVar(AToks[TokIdx].Up);
          if (VarRec <> nil) and (VarRec.RqType = 'STRING') then
            Result := True;
          ProcRec := FindProc(AToks[TokIdx].Up);
          if (ProcRec <> nil) and ProcRec.IsFunc and
             (ProcRec.RetType = 'STRING') then
            Result := True;
        end;
      end;
      if Result then
        Exit;
    end;
  end;
end;

// Выражение - явно числовое: на верхнем уровне только числа и числовые
// переменные (свойства объектов и функции - тип неизвестен)
function TRqFbConv.ExprIsNumber(const AToks: TToks; AFrom, ATo: Integer): Boolean;
var
  TokIdx, Depth: Integer;
  VarRec: TRqVar;
  HasOperand: Boolean;
begin
  Result := False;
  HasOperand := False;
  Depth := 0;
  for TokIdx := AFrom to ATo do
  begin
    if IsOp(AToks, TokIdx, '(') then
      Inc(Depth)
    else if IsOp(AToks, TokIdx, ')') then
      Dec(Depth)
    else if Depth = 0 then
      case AToks[TokIdx].Kind of
        tkNumber:
          HasOperand := True;
        tkString:
          Exit;
        tkIdent:
          begin
            if InList(FKeywords, AToks[TokIdx].Up) and
               ((AToks[TokIdx].Up = 'AND') or (AToks[TokIdx].Up = 'OR') or
                (AToks[TokIdx].Up = 'MOD') or (AToks[TokIdx].Up = 'XOR') or
                (AToks[TokIdx].Up = 'NOT')) then
              Continue;
            VarRec := FindVar(AToks[TokIdx].Up);
            if (VarRec = nil) or not IsNumericType(VarRec.RqType) or
               IsOp(AToks, NextSig(AToks, TokIdx + 1, ATo), '.') then
              Exit;
            HasOperand := True;
          end;
      end;
  end;
  Result := HasOperand;
end;

// Строка RapidQ при $ESCAPECHARS ON -> строка FreeBASIC !"..."
// (\xHH -> \&hHH, \### -> \&hHH; остальные \a \b \f \n \r \t \v \\ \"
// у FreeBASIC те же)
function TRqFbConv.EscapeString(const AText: string): string;
var
  CharIdx, CodeValue, DigitCount: Integer;
begin
  Result := '!"';
  CharIdx := 2;
  while CharIdx < Length(AText) do
  begin
    if (AText[CharIdx] = '\') and (CharIdx + 1 < Length(AText)) then
    begin
      if (AText[CharIdx + 1] in ['x', 'X']) and (CharIdx + 3 < Length(AText)) then
      begin
        Result := Result + '\&h' + Copy(AText, CharIdx + 2, 2);
        Inc(CharIdx, 4);
        Continue;
      end;
      if AText[CharIdx + 1] in ['0'..'9'] then
      begin
        CodeValue := 0;
        DigitCount := 0;
        while (DigitCount < 3) and (CharIdx + 1 + DigitCount < Length(AText)) and
              (AText[CharIdx + 1 + DigitCount] in ['0'..'9']) and
              (CodeValue * 10 + Ord(AText[CharIdx + 1 + DigitCount]) - 48 <= 255) do
        begin
          CodeValue := CodeValue * 10 + Ord(AText[CharIdx + 1 + DigitCount]) - 48;
          Inc(DigitCount);
        end;
        Result := Result + '\&h' + IntToHex(CodeValue, 2);
        Inc(CharIdx, 1 + DigitCount);
        Continue;
      end;
      Result := Result + AText[CharIdx] + AText[CharIdx + 1];
      Inc(CharIdx, 2);
      Continue;
    end;
    Result := Result + AText[CharIdx];
    Inc(CharIdx);
  end;
  Result := Result + '"';
end;

// ---------------------------------------------------------------------------
//  Строка: условная компиляция, директивы, разбиение на операторы по ":"
// ---------------------------------------------------------------------------

procedure TRqFbConv.ProcessLine(const AText: string; var AOut: string);
var
  Toks: TToks;
  Text, FirstUp, CondName: string;
  FirstIdx, TokIdx, StartIdx, Depth, LastIdx, NameIdx: Integer;
  Cond: TCondRec;
  IsDefined: Boolean;
begin
  Text := ApplyDefines(AText);
  FLineBreaks := CountLineBreaks(AText);
  // Внутри TYPE ... EXTENDS - обращения к членам через This; иначе
  // CREATE ... END CREATE - переписать строку до разбора
  if CondActive and (FCurType <> nil) then
    Text := RewriteTypeText(Text)
  else if CondActive then
    Text := RewriteCreate(Text);
  Lex(Text, Toks);
  AOut := Text;
  // '$RQFB SMART / '$RQFB COMPAT - режим перевода из исходника (строка -
  // комментарий, rc.exe RapidQ её пропускает)
  for TokIdx := 0 to High(Toks) do
    if (Toks[TokIdx].Kind = tkComment) and
       (UpperCase(Copy(Toks[TokIdx].Text, 1, 6)) = '''$RQFB') then
    begin
      CondName := UpperCase(Trim(Copy(Toks[TokIdx].Text, 7, MaxInt)));
      if (CondName = 'SMART') or (CondName = 'COMPAT') then
        FSourceMode := CondName
      else
        Warn('''$RQFB ' + CondName + ': ожидалось SMART или COMPAT');
    end;
  FirstIdx := NextSig(Toks, 0, High(Toks));
  if FirstIdx < 0 then
    Exit;
  FirstUp := Toks[FirstIdx].Up;

  // $IFDEF / $IFNDEF / $ELSE / $ENDIF выполняются здесь же
  if (Toks[FirstIdx].Kind = tkDirective) and
     ((FirstUp = '$IFDEF') or (FirstUp = '$IFNDEF') or (FirstUp = '$ELSE') or
      (FirstUp = '$ENDIF')) then
  begin
    AOut := CommentOut(AText);
    if (FirstUp = '$IFDEF') or (FirstUp = '$IFNDEF') then
    begin
      NameIdx := NextSig(Toks, FirstIdx + 1, High(Toks));
      CondName := '';
      if NameIdx >= 0 then
        CondName := Toks[NameIdx].Up;
      IsDefined := FDefines.IndexOfName(CondName) >= 0;
      Cond.ParentActive := CondActive;
      if FirstUp = '$IFDEF' then
        Cond.Active := Cond.ParentActive and IsDefined
      else
        Cond.Active := Cond.ParentActive and not IsDefined;
      Cond.ElseSeen := False;
      SetLength(FConds, Length(FConds) + 1);
      FConds[High(FConds)] := Cond;
    end
    else if FirstUp = '$ELSE' then
    begin
      if Length(FConds) = 0 then
        Error('$ELSE без $IFDEF')
      else
        with FConds[High(FConds)] do
        begin
          Active := ParentActive and not Active and not ElseSeen;
          ElseSeen := True;
        end;
    end
    else
    begin
      if Length(FConds) = 0 then
        Error('$ENDIF без $IFDEF')
      else
        SetLength(FConds, Length(FConds) - 1);
    end;
    Exit;
  end;

  if not CondActive then
  begin
    AOut := CommentOut(AText);
    Exit;
  end;

  // Тело функции-обхода RapidQ (SetNewWndProc и др.) - заменено в
  // заголовке (CallbackShimBody), до END FUNCTION строки - комментарии
  if FSkipBody then
  begin
    if (FirstUp = 'END') and IsWord(Toks, NextSig(Toks, FirstIdx + 1, High(Toks)),
                                    'FUNCTION') then
    begin
      FSkipBody := False;
      FCurProc := nil;
      AOut := 'End Function';
    end
    else
      AOut := CommentOut(AText);
    Exit;
  end;

  // Метка в начале строки: Имя:
  FLineIsLabel := False;
  FInlineIf := False;
  StartIdx := 0;
  if (Toks[FirstIdx].Kind = tkIdent) and
     IsOp(Toks, NextSig(Toks, FirstIdx + 1, High(Toks)), ':') and
     not InList(FKeywords, FirstUp) and (FindProc(FirstUp) = nil) then
  begin
    if FPass = 1 then
      FLabels.Add(FirstUp);
    StartIdx := NextSig(Toks, FirstIdx + 1, High(Toks)) + 1;
  end;

  // Директивы - строкой целиком
  if Toks[FirstIdx].Kind = tkDirective then
  begin
    if ProcessDirective(Toks, FirstIdx, High(Toks), AOut) then
      Exit;
  end;

  // Операторы через ":" на верхнем уровне скобок; комментарий - конец
  Depth := 0;
  LastIdx := High(Toks);
  for TokIdx := StartIdx to High(Toks) do
    if Toks[TokIdx].Kind = tkComment then
    begin
      LastIdx := TokIdx - 1;
      Break;
    end;
  TokIdx := StartIdx;
  while TokIdx <= LastIdx do
  begin
    if IsOp(Toks, TokIdx, '(') then
      Inc(Depth)
    else if IsOp(Toks, TokIdx, ')') then
      Dec(Depth)
    else if (Depth = 0) and IsOp(Toks, TokIdx, ':') then
    begin
      if TokIdx - 1 >= StartIdx then
        ProcessStatement(Toks, StartIdx, TokIdx - 1);
      StartIdx := TokIdx + 1;
    end;
    Inc(TokIdx);
  end;
  if StartIdx <= LastIdx then
    ProcessStatement(Toks, StartIdx, LastIdx);

  AOut := '';
  for TokIdx := 0 to High(Toks) do
    AOut := AOut + Toks[TokIdx].Pre + Toks[TokIdx].OutText + Toks[TokIdx].Post;
end;

// Класс есть в rqmembers.inc
function TRqFbConv.ClassKnown(const AClassUp: string): Boolean;
var
  Found: Integer;
begin
  FClassMembers.Find(AClassUp + '.', Found);
  Result := (Found < FClassMembers.Count) and
            (Copy(FClassMembers[Found], 1, Length(AClassUp) + 1) = AClassUp + '.');
end;

// Вид слова у любого класса из списка (свойство, если хоть у одного)
function TRqFbConv.AnyMemberKind(const AMemberUp: string): Char;
var
  ItemIdx: Integer;
begin
  ItemIdx := FAllMembers.IndexOfName(AMemberUp);
  if ItemIdx < 0 then
    Result := #0
  else
    Result := FAllMembers.ValueFromIndex[ItemIdx][1];
end;

function TRqFbConv.MemberKind(const AClassUp, AMemberUp: string): Char;
var
  Found: Integer;
  Item: string;
begin
  Result := #0;
  // ищется 'КЛАСС.ИМЯ=': Find в отсортированном списке по началу строки
  FClassMembers.Find(AClassUp + '.' + AMemberUp + '=', Found);
  if Found < FClassMembers.Count then
  begin
    Item := FClassMembers[Found];
    if Copy(Item, 1, Length(AClassUp) + Length(AMemberUp) + 2) =
       AClassUp + '.' + AMemberUp + '=' then
      Result := Item[Length(Item)];
  end;
end;

// CREATE Имя AS Класс ... END CREATE (документация RapidQ, глава 5.6-5.7):
//   CREATE Имя AS Класс -> DIM Имя AS Класс (+ Имя.Parent = Внешний у
//     вложенного CREATE элемента; у пункта меню - Внешний.AddItems Имя);
//   Свойство = x, Метод, Метод арг внутри -> Имя.Свойство = x, Имя.Метод...;
//   Метод = a, b (AddOptions = goEditing, goTabs) -> Имя.Метод a, b;
//   END CREATE -> убирается.
// Слово в начале оператора - свойство объекта, если оно есть в списке
// класса (rqmembers.inc); класса нет в списке (свой TYPE EXTENDS) или
// слова нет - свойство, если это не переменная, не процедура и не
// ключевое слово.
function TRqFbConv.RewriteCreate(const AText: string): string;
var
  Toks: TToks;
  TokIdx, StartIdx, LastIdx, Depth, FirstIdx, NameIdx, AsIdx, ClassIdx,
    NextIdx: Integer;
  ObjName, ClassUp, OuterName, OuterClass, Up: string;
  Kind: Char;
  Changed: Boolean;
  OwnInfo: TRqTypeInfo;

  procedure DoStatement(AFrom, ATo: Integer);
  var
    ClearIdx: Integer;
  begin
    FirstIdx := NextSig(Toks, AFrom, ATo);
    if FirstIdx < 0 then
      Exit;
    Up := Toks[FirstIdx].Up;
    if (Toks[FirstIdx].Kind = tkIdent) and (Up = 'CREATE') then
    begin
      NameIdx := NextSig(Toks, FirstIdx + 1, ATo);
      AsIdx := NextSig(Toks, NameIdx + 1, ATo);
      ClassIdx := NextSig(Toks, AsIdx + 1, ATo);
      if (NameIdx < 0) or (Toks[NameIdx].Kind <> tkIdent) or
         not IsWord(Toks, AsIdx, 'AS') or (ClassIdx < 0) then
      begin
        if FPass = 2 then
          Error('CREATE: ожидалось CREATE Имя AS Класс');
        Exit;
      end;
      ObjName := Toks[NameIdx].Text;
      ClassUp := Toks[ClassIdx].Up;
      // свой компонент - правила его класса RapidQ
      OwnInfo := FindTypeInfo(ClassUp);
      if OwnInfo <> nil then
        ClassUp := OwnInfo.BaseClass;
      Toks[FirstIdx].Text := 'DIM';
      if FCreateStack.Count > 0 then
      begin
        OuterName := FCreateStack.Names[FCreateStack.Count - 1];
        OuterClass := FCreateStack.ValueFromIndex[FCreateStack.Count - 1];
        if FindTypeInfo(OuterClass) <> nil then
          OuterClass := FindTypeInfo(OuterClass).BaseClass;
        if (ClassUp = 'QMENUITEM') and
           ((OuterClass = 'QMENUITEM') or (OuterClass = 'QMAINMENU') or
            (OuterClass = 'QPOPUPMENU')) then
          Toks[ATo].Post := Toks[ATo].Post + ' : ' + OuterName + '.AddItems ' + ObjName
        else if ClassUp = 'QMAINMENU' then
          // меню формы
          Toks[ATo].Post := Toks[ATo].Post + ' : ' + ObjName + '.Parent = ' + OuterName
        else if (ClassUp = 'QPOPUPMENU') or
                (Pos(' ' + ClassUp + ' ', ' ' + RqNonVisualText + ' ') > 0) then
          // всплывающее меню не имеет родителя: элемент получает его
          // через PopupMenu = Имя; QOBJECT - не элемент окна
        else if InList(FObjClasses, ClassUp) and (MemberKind(ClassUp, 'PARENT') = #0) and
                ClassKnown(ClassUp) and (MemberKind(ClassUp, 'LEFT') = #0) then
          // невидимый компонент (QTIMER, QSTRINGLIST...) - без родителя
        // Parent есть у класса по списку; класса нет в списке (свой
        // компонент, QBUTTONXP...) - считается элементом с Parent
        else if (MemberKind(ClassUp, 'PARENT') <> #0) or
                not ClassKnown(ClassUp) then
          Toks[ATo].Post := Toks[ATo].Post + ' : ' + ObjName + '.Parent = ' + OuterName
        else if FPass = 2 then
          Warn('CREATE ' + ObjName + ' AS ' + Toks[ClassIdx].Text +
               ' внутри CREATE ' + OuterName + ': у класса нет Parent, ' +
               'объект создан без родителя');
      end;
      FCreateStack.Add(ObjName + '=' + Toks[ClassIdx].Up);
      Changed := True;
      Exit;
    end;
    if FCreateStack.Count = 0 then
      Exit;
    if (Toks[FirstIdx].Kind = tkIdent) and (Up = 'END') then
    begin
      NextIdx := NextSig(Toks, FirstIdx + 1, ATo);
      if IsWord(Toks, NextIdx, 'CREATE') then
      begin
        FCreateStack.Delete(FCreateStack.Count - 1);
        for ClearIdx := AFrom to ATo do
          if Toks[ClearIdx].Kind <> tkSpace then
            Toks[ClearIdx].Text := '';
        Changed := True;
      end;
      Exit;
    end;
    if Toks[FirstIdx].Kind <> tkIdent then
      Exit;
    NextIdx := NextSig(Toks, FirstIdx + 1, ATo);
    ObjName := FCreateStack.Names[FCreateStack.Count - 1];
    ClassUp := FCreateStack.ValueFromIndex[FCreateStack.Count - 1];
    Kind := #0;
    // Свой компонент: его поля и методы, затем - его класса RapidQ
    OwnInfo := FindTypeInfo(ClassUp);
    if OwnInfo <> nil then
    begin
      case OwnInfo.Kind(Up) of
        'F', 'P', 'E': Kind := 'P';
        'M', 'N', 'S': Kind := 'M';
      end;
      ClassUp := OwnInfo.BaseClass;
    end;
    if Kind = #0 then
      Kind := MemberKind(ClassUp, Up);
    // Свой класс (TYPE ... EXTENDS, $DEFINE QRICHEDIT QMAXEDIT): вид слова
    // - по любому классу из списка
    if (Kind = #0) and not ClassKnown(ClassUp) then
      Kind := AnyMemberKind(Up);
    // Объект.Свойство - как есть; но Font.Name = "Arial" внутри CREATE -
    // шрифт этого объекта (Font - свойство класса)
    if IsOp(Toks, NextIdx, '.') and (Kind <> 'P') then
      Exit;
    if Kind = #0 then
    begin
      if InList(FKeywords, Up) or InList(FTypes, Up) or
         (FindVar(Up) <> nil) or (FindProc(Up) <> nil) or
         InList(FFbStrFuncs, Up) or InList(FRqStrFuncs, Up) then
        Exit;
      if FPass = 2 then
      begin
        if ClassKnown(ClassUp) then
          WarnOnce('CM|' + ClassUp + '|' + Up, Toks[FirstIdx].Text +
            ' внутри CREATE ' + ObjName + ': в списке свойств ' + ClassUp +
            ' нет, считается свойством объекта')
        else
          WarnOnce('CC|' + ClassUp, ClassUp + ' (CREATE ' + ObjName +
            '): класса нет в документации RapidQ - слова в начале ' +
            'операторов внутри CREATE считаются его свойствами');
      end;
    end;
    Toks[FirstIdx].Text := ObjName + '.' + Toks[FirstIdx].Text;
    // Метод = a, b -> Объект.Метод a, b
    if (Kind = 'M') and IsOp(Toks, NextIdx, '=') then
      Toks[NextIdx].Text := ' ';
    Changed := True;
  end;

begin
  Result := AText;
  // быстрый выход: вне CREATE и без слова CREATE
  if (FCreateStack.Count = 0) and (Pos('CREATE', UpperCase(AText)) = 0) then
    Exit;
  Lex(AText, Toks);
  Changed := False;
  LastIdx := High(Toks);
  for TokIdx := 0 to High(Toks) do
    if Toks[TokIdx].Kind = tkComment then
    begin
      LastIdx := TokIdx - 1;
      Break;
    end;
  FirstIdx := NextSig(Toks, 0, LastIdx);
  if (FirstIdx >= 0) and (Toks[FirstIdx].Kind = tkDirective) then
    Exit;
  Depth := 0;
  StartIdx := 0;
  TokIdx := 0;
  while TokIdx <= LastIdx do
  begin
    if IsOp(Toks, TokIdx, '(') then
      Inc(Depth)
    else if IsOp(Toks, TokIdx, ')') then
      Dec(Depth)
    else if (Depth = 0) and IsOp(Toks, TokIdx, ':') then
    begin
      if TokIdx - 1 >= StartIdx then
        DoStatement(StartIdx, TokIdx - 1);
      StartIdx := TokIdx + 1;
    end;
    Inc(TokIdx);
  end;
  if StartIdx <= LastIdx then
    DoStatement(StartIdx, LastIdx);
  if not Changed then
    Exit;
  Result := '';
  for TokIdx := 0 to High(Toks) do
    Result := Result + Toks[TokIdx].Pre + Toks[TokIdx].Text + Toks[TokIdx].Post;
end;

// Директива в начале строки. True - строка выведена целиком (AOut).
function TRqFbConv.ProcessDirective(var AToks: TToks; AFrom, ATo: Integer;
                                    var AOut: string): Boolean;
var
  Name, Value, IncName, Found, OutPath, Original: string;
  ArgIdx, CloseIdx, TokIdx, DefIdx: Integer;
  Angle: Boolean;
begin
  Result := True;
  Name := AToks[AFrom].Up;
  Original := '';
  for TokIdx := AFrom to ATo do
    Original := Original + AToks[TokIdx].Text;
  AOut := CommentOut(Original);
  ArgIdx := NextSig(AToks, AFrom + 1, ATo);
  Value := '';
  if ArgIdx >= 0 then
    Value := AToks[ArgIdx].Up;

  if Name = '$INCLUDE' then
  begin
    IncName := '';
    Angle := False;
    if (ArgIdx >= 0) and (AToks[ArgIdx].Kind = tkString) then
      IncName := Copy(AToks[ArgIdx].Text, 2, Length(AToks[ArgIdx].Text) - 2)
    else if IsOp(AToks, ArgIdx, '<') then
    begin
      Angle := True;
      CloseIdx := ArgIdx + 1;
      while (CloseIdx <= ATo) and not IsOp(AToks, CloseIdx, '>') do
      begin
        IncName := IncName + AToks[CloseIdx].Text;
        Inc(CloseIdx);
      end;
    end;
    IncName := Trim(IncName);
    if IncName = '' then
    begin
      Error('$INCLUDE: не указан файл');
      Exit;
    end;
    Found := ResolveInclude(IncName, Angle);
    if Found = '' then
    begin
      Error('$INCLUDE: файл не найден: ' + IncName);
      Exit;
    end;
    // Полный путь: после #line fbc ищет относительные пути от папки
    // исходника RapidQ, а не от папки переведённого файла
    OutPath := ProcessFile(Found, False);
    AOut := '#include once "' + OutPath + '"';
    Exit;
  end;

  if Name = '$DEFINE' then
  begin
    if (ArgIdx >= 0) and (AToks[ArgIdx].Kind = tkIdent) then
    begin
      Value := '';
      for TokIdx := ArgIdx + 1 to ATo do
        if AToks[TokIdx].Kind <> tkComment then
          Value := Value + AToks[TokIdx].Text;
      Value := Trim(Value);
      DefIdx := FDefines.IndexOfName(AToks[ArgIdx].Up);
      if DefIdx >= 0 then
        FDefines.Delete(DefIdx);
      FDefines.Add(AToks[ArgIdx].Up + '=' + Value);
    end
    else if (ArgIdx >= 0) and (AToks[ArgIdx].Kind = tkDirective) and
            (AToks[ArgIdx].Up = '$DEFINE') then
      // $define #define $define - #define и так означает $DEFINE
    else
      WarnOnce('DEFINE|' + RawText(AToks, ArgIdx, ArgIdx),
               '$DEFINE ' + RawText(AToks, ArgIdx, ArgIdx) +
               ': переопределение знаков не поддержано');
    Exit;
  end;

  if Name = '$UNDEF' then
  begin
    for TokIdx := ArgIdx to ATo do
      if (TokIdx >= 0) and (AToks[TokIdx].Kind = tkIdent) then
      begin
        DefIdx := FDefines.IndexOfName(AToks[TokIdx].Up);
        if DefIdx >= 0 then
          FDefines.Delete(DefIdx);
      end;
    Exit;
  end;

  if Name = '$TYPECHECK' then
  begin
    FTypeCheck := Value = 'ON';
    Exit;
  end;

  if Name = '$APPTYPE' then
  begin
    if (Value = 'CONSOLE') or (Value = 'GUI') then
      FAppType := Value
    else if Value = 'CGI' then
    begin
      FAppType := 'CONSOLE';
      Warn('$APPTYPE CGI: собирается как CONSOLE');
    end;
    Exit;
  end;

  if Name = '$ESCAPECHARS' then
  begin
    FEscape := Value = 'ON';
    Exit;
  end;

  if Name = '$OPTIMIZE' then
    Exit;

  if Name = '$OPTION' then
  begin
    TokIdx := NextSig(AToks, ArgIdx + 1, ATo);
    if Value = 'DIM' then
    begin
      if TokIdx >= 0 then
        FDefaultType := NormType(AToks[TokIdx].Up);
    end
    else if Value = 'EXPLICIT' then
      FTypeCheck := True
    else if Value = 'BYREF' then
      FByRefDefault := True
    else
      Warn('$OPTION ' + Value + ': не поддержано, пропущено');
    Exit;
  end;

  // $RESOURCE Имя AS "файл" / <файл> (глава 8): файл встраивается в exe,
  // Имя - номер ресурса (константа)
  if Name = '$RESOURCE' then
  begin
    ProcessResource(AToks, AFrom, ATo, ArgIdx, Original, AOut);
    Exit;
  end;

  if Name = '$MACRO' then
  begin
    Warn(AToks[AFrom].Text + ': пока не поддержано, строка пропущена');
    Exit;
  end;

  Warn(AToks[AFrom].Text + ': неизвестная директива, строка пропущена');
end;

function TRqFbConv.ResolveInclude(const AName: string; AAngle: Boolean): string;
var
  Dirs: TStringList;
  DirIdx: Integer;
  NameFixed: string;
begin
  Result := '';
  NameFixed := StringReplace(AName, '\', PathDelim, [rfReplaceAll]);
  NameFixed := StringReplace(NameFixed, '/', PathDelim, [rfReplaceAll]);
  if (ExtractFileDrive(NameFixed) <> '') or (Copy(NameFixed, 1, 1) = PathDelim) then
  begin
    Result := FindFileCI(NameFixed);
    Exit;
  end;
  Dirs := TStringList.Create;
  try
    Dirs.Add(ExtractFilePath(FCurFile));
    Dirs.Add(ExtractFilePath(FMainFile));
    Dirs.Text := Dirs.Text + StringReplace(FOpt.IncDirs, ';', CrLf, [rfReplaceAll]);
    if AAngle then
      Dirs.Text := Dirs.Text + StringReplace(GetEnvironmentVariable('PATH'), ';',
                                             CrLf, [rfReplaceAll]);
    for DirIdx := 0 to Dirs.Count - 1 do
      if Trim(Dirs[DirIdx]) <> '' then
      begin
        Result := FindFileCI(IncludeTrailingPathDelimiter(Trim(Dirs[DirIdx])) +
                             NameFixed);
        if Result <> '' then
          Exit;
      end;
  finally
    Dirs.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  Операторы
// ---------------------------------------------------------------------------

procedure TRqFbConv.ProcessStatement(var AToks: TToks; AFrom, ATo: Integer);
var
  FirstIdx, NextIdx: Integer;
  Up: string;
begin
  FirstIdx := NextSig(AToks, AFrom, ATo);
  if FirstIdx < 0 then
    Exit;
  if AToks[FirstIdx].Kind = tkDirective then
  begin
    Warn(AToks[FirstIdx].Text + ': директива не в начале строки, пропущена');
    Exit;
  end;
  if IsOp(AToks, FirstIdx, '?') then
  begin
    ProcessPrint(AToks, FirstIdx, ATo);
    Exit;
  end;
  // .Свойство = x внутри WITH Объект - как Объект.Свойство = x
  if IsOp(AToks, FirstIdx, '.') then
  begin
    ProcessAssignOrCall(AToks, FirstIdx, ATo);
    Exit;
  end;
  if AToks[FirstIdx].Kind <> tkIdent then
  begin
    ProcessExpr(AToks, FirstIdx, ATo);
    Exit;
  end;
  Up := AToks[FirstIdx].Up;
  NextIdx := NextSig(AToks, FirstIdx + 1, ATo);

  // Перем ++
  if not InList(FKeywords, Up) and ProcessPlusPlus(AToks, FirstIdx, ATo) then
    Exit;

  // Внутри TYPE ... EXTENDS: заголовки и концы методов, поля
  if (FCurType <> nil) and TypeStatement(AToks, FirstIdx, ATo) then
    Exit;

  if Up = 'REM' then
    Exit;
  if (Up = 'DIM') or (Up = 'REDIM') then
    ProcessDim(AToks, FirstIdx, ATo)
  else if (Copy(Up, 1, 3) = 'DEF') and
          ((Up = 'DEFINT') or (Up = 'DEFSTR') or (Up = 'DEFDBL') or
           (Up = 'DEFSNG') or (Up = 'DEFBYTE') or (Up = 'DEFWORD') or
           (Up = 'DEFDWORD') or (Up = 'DEFLNG') or (Up = 'DEFSHORT')) then
    ProcessDef(AToks, FirstIdx, ATo)
  // PRIVATE / PUBLIC перед CONST, TYPE, DECLARE, SUB, FUNCTION, DIM (как в
  // VB; Form.inc: Private Type POINTAPI, Private Declare Function ...) -
  // слово убирается, остальное - обычный оператор
  else if ((Up = 'PUBLIC') or (Up = 'PRIVATE')) and (NextIdx >= 0) and
          (Pos(' ' + AToks[NextIdx].Up + ' ',
               ' CONST TYPE DECLARE SUB FUNCTION SUBI FUNCTIONI DIM ') > 0) then
  begin
    AToks[FirstIdx].OutText := '';
    if (FirstIdx + 1 < NextIdx) and (AToks[FirstIdx + 1].Kind = tkSpace) then
      AToks[FirstIdx + 1].OutText := '';
    ProcessStatement(AToks, NextIdx, ATo);
  end
  else if Up = 'CONST' then
    ProcessConst(AToks, FirstIdx, ATo)
  else if (Up = 'SUB') or (Up = 'FUNCTION') or (Up = 'SUBI') or
          (Up = 'FUNCTIONI') then
    ProcessProcHeader(AToks, FirstIdx, ATo)
  else if Up = 'END' then
  begin
    if IsWord(AToks, NextIdx, 'SUB') or IsWord(AToks, NextIdx, 'FUNCTION') or
       IsWord(AToks, NextIdx, 'SUBI') or IsWord(AToks, NextIdx, 'FUNCTIONI') then
    begin
      FCurProc := nil;
      if IsWord(AToks, NextIdx, 'SUBI') then
        AToks[NextIdx].OutText := 'Sub'
      else if IsWord(AToks, NextIdx, 'FUNCTIONI') then
        AToks[NextIdx].OutText := 'Function';
    end
    else if IsWord(AToks, NextIdx, 'TYPE') then
    begin
      // свойства полей STRING*N - той же строкой
      if FInType and (FFixBodies <> '') then
        AToks[NextIdx].OutText := AToks[NextIdx].OutText + FFixBodies;
      FFixBodies := '';
      FPlainType := '';
      FInType := False;
    end
    else if IsWord(AToks, NextIdx, 'CREATE') then
    begin
      if FCreateDepth > 0 then
        Dec(FCreateDepth);
    end;
  end
  else if Up = 'DECLARE' then
    ProcessDeclare(AToks, FirstIdx, ATo)
  else if Up = 'TYPE' then
    ProcessTypeHeader(AToks, FirstIdx, ATo)
  else if Up = 'CREATE' then
  begin
    Inc(FCreateDepth);
    WarnOnce('CREATE', 'CREATE ... END CREATE пока не поддержано');
  end
  else if (Up = 'PRINT') or (Up = 'LPRINT') then
  begin
    if Up = 'LPRINT' then
      WarnOnce('LPRINT', 'LPRINT пока не поддержан');
    ProcessPrint(AToks, FirstIdx, ATo);
  end
  else if (Up = 'IF') or (Up = 'ELSEIF') then
    ProcessIf(AToks, FirstIdx, ATo)
  else if Up = 'ELSE' then
    ProcessStatement(AToks, FirstIdx + 1, ATo)
  else if Up = 'FOR' then
    ProcessFor(AToks, FirstIdx, ATo)
  else if Up = 'CALL' then
  begin
    AToks[FirstIdx].OutText := '';
    ProcessAssignOrCall(AToks, FirstIdx + 1, ATo);
  end
  else if Up = 'LET' then
  begin
    AToks[FirstIdx].OutText := '';
    ProcessAssignOrCall(AToks, FirstIdx + 1, ATo);
  end
  else if Up = 'GOTO' then
    // метка
  else if Up = 'GOSUB' then
    ProcessGosub(AToks, FirstIdx, ATo)
  else if Up = 'RETURN' then
    ProcessReturn(AToks, FirstIdx, ATo)
  else if (Up = 'INC') or (Up = 'DEC') then
    ProcessIncDec(AToks, FirstIdx, ATo)
  else if (Up = 'BIND') and (FindProc(Up) = nil) then
    ProcessBind(AToks, FirstIdx, ATo)
  else if (Up = 'CALLFUNC') and (FindProc(Up) = nil) and
          ((FCurType = nil) or (FTypeBody = 0)) then
    ProcessCallFuncStmt(AToks, FirstIdx, ATo)
  else if (Up = 'SLEEP') and (FindProc(Up) = nil) then
  begin
    // SLEEP секунды (RapidQ, можно дробь) -> RqSleep; Sleep FreeBASIC - в
    // миллисекундах. Свой DECLARE SUB Sleep LIB "kernel32" - как есть
    AToks[FirstIdx].OutText := 'RqSleep';
    ProcessExpr(AToks, FirstIdx + 1, ATo);
  end
  else if FInType then
    ProcessField(AToks, FirstIdx, ATo)
  // CASE = x - как CASE x (тест пользователя 2026-10-08: x = 0, CASE = 0
  // совпало). CASE > x и др. в RapidQ - не сравнение (x = 7, CASE > 5 не
  // совпало, ушло в CASE ELSE); что это значит, не выяснено - ошибка перевода
  else if (Up = 'CASE') and IsOp(AToks, NextIdx, '=') then
  begin
    AToks[NextIdx].OutText := '';
    ProcessExpr(AToks, NextIdx + 1, ATo);
  end
  else if (Up = 'CASE') and (NextIdx >= 0) and (AToks[NextIdx].Kind = tkOp) and
          (Pos(' ' + AToks[NextIdx].Text + ' ', ' < > <= >= <> ') > 0) then
    Error('CASE ' + AToks[NextIdx].Text + ' ...: в RapidQ это не сравнение ' +
          '(тест: x = 7, CASE > 5 не совпало); сравнение в RapidQ - CASE IS ' +
          AToks[NextIdx].Text + ' ... (conditions.html)')
  else if InList(FKeywords, Up) and (FindProc(Up) = nil) and
          not IsOp(AToks, NextIdx, '=') and not IsOp(AToks, NextIdx, '(') and
          not IsOp(AToks, NextIdx, '.') then
    // оператор RapidQ (SELECT CASE, DO, LOOP, NEXT, WHILE, RETURN...):
    // дальше - выражения
    ProcessExpr(AToks, FirstIdx + 1, ATo)
  else
    ProcessAssignOrCall(AToks, FirstIdx, ATo);
end;

// Выражение: переменные переименовываются, необъявленные заводятся
procedure TRqFbConv.ProcessExpr(var AToks: TToks; AFrom, ATo: Integer);
var
  TokIdx, PrevIdx: Integer;
begin
  RewriteStrSub(AToks, AFrom, ATo);
  for TokIdx := AFrom to ATo do
    case AToks[TokIdx].Kind of
      tkIdent:
        ProcessIdent(AToks, TokIdx, ATo);
      tkString:
        if FEscape then
          AToks[TokIdx].OutText := EscapeString(AToks[TokIdx].Text);
      tkOp:
        if AToks[TokIdx].Text = '@' then
        begin
          // StrCat @A$ - передача по ссылке при вызове
          PrevIdx := PrevSig(AToks, TokIdx - 1);
          if (PrevIdx < AFrom) or IsOp(AToks, PrevIdx, ',') or
             IsOp(AToks, PrevIdx, '(') or (AToks[PrevIdx].Kind = tkIdent) then
          begin
            AToks[TokIdx].OutText := '';
            Warn('передача по ссылке через @ при вызове не поддержана - ' +
                 'параметр получит копию (объявите его BYREF)');
          end;
        end;
    end;
end;

procedure TRqFbConv.ProcessIdent(var AToks: TToks; AIdx, ATo: Integer);
var
  Up: string;
  PrevIdx, NextIdx: Integer;
  VarRec: TRqVar;
  ProcRec: TRqProc;
begin
  Up := AToks[AIdx].Up;
  PrevIdx := PrevSig(AToks, AIdx - 1);
  if IsOp(AToks, PrevIdx, '.') then
  begin
    // Член своего компонента через This: поле с PROPERTY SET внутри
    // TYPE - само значение (RqVal_Имя), без вызова установщика
    if (FCurType <> nil) and IsWord(AToks, PrevSig(AToks, PrevIdx - 1), 'THIS') and
       (FCurType.Kind(Up) <> #0) then
    begin
      if FCurType.Kind(Up) = 'P' then
        AToks[AIdx].OutText := 'RqVal_' + FCurType.MemberFb.Values[Up]
      else
        AToks[AIdx].OutText := FCurType.MemberFb.Values[Up];
    end
    // свойство или метод объекта
    else if FMemberMap.IndexOfName(Up) >= 0 then
      AToks[AIdx].OutText := FMemberMap.Values[Up];
    // метод SUBI / FUNCTIONI своего компонента
    if VariadicMember(AToks, AIdx) then
    begin
      NextIdx := NextSig(AToks, AIdx + 1, ATo);
      if IsOp(AToks, NextIdx, '(') and (MatchParen(AToks, NextIdx, ATo) > 0) then
        WrapVariadicArgs(AToks, NextIdx + 1, MatchParen(AToks, NextIdx, ATo) - 1,
                         AIdx, True)
      else if (NextIdx < 0) or ((AToks[NextIdx].Kind = tkOp) and
              (AToks[NextIdx].Text <> '(')) or IsWord(AToks, NextIdx, 'THEN') or
              IsWord(AToks, NextIdx, 'ELSE') or IsWord(AToks, NextIdx, 'AND') or
              IsWord(AToks, NextIdx, 'OR') or IsWord(AToks, NextIdx, 'TO') then
        // без параметров в выражении (x = Obj.F + 1)
        AToks[AIdx].Post := AToks[AIdx].Post + '(RqPList())';
    end;
    Exit;
  end;
  NextIdx := NextSig(AToks, AIdx + 1, ATo);
  // Super.x внутри TYPE ... EXTENDS -> Base.x
  if (Up = 'SUPER') and (FCurType <> nil) and IsOp(AToks, NextIdx, '.') then
  begin
    AToks[AIdx].OutText := 'Base';
    Exit;
  end;
  // TRUE / FALSE - не слова RapidQ: значение задаёт rapidq.inc ($define
  // True 1 - подставляется ещё при чтении строки) или CONST программы.
  // Без определения - необъявленная переменная, 0 (тест в RapidQ
  // 2026-10-08: PRINT TRUE -> 0, NOT TRUE -> -1). В FreeBASIC True -
  // слово языка, имя переменной - TRUE_v (Mangle).
  if (Up = 'TRUE') or (Up = 'FALSE') then
  begin
    VarRec := ResolveVar(AToks[AIdx].Text, False);
    AToks[AIdx].OutText := VarRec.FbName;
    if not VarRec.Explicit then
      WarnOnce('TF|' + Up, AToks[AIdx].Text + ': не определено (нет $INCLUDE ' +
        '"RAPIDQ.INC" или CONST) - в RapidQ это необъявленная переменная, 0')
    else if (VarRec.Scope = '') then
      GlobalQualify(AToks, AIdx);
    Exit;
  end;

  // ParamStrCount, ParamValCount, ParamStr$(i), ParamVal(i) в SUBI /
  // FUNCTIONI - из списка параметров RqParams
  if (FCurProc <> nil) and FCurProc.IsVariadic then
  begin
    if Up = 'PARAMSTRCOUNT' then
    begin
      AToks[AIdx].OutText := 'RqParams.StrCount';
      Exit;
    end;
    if Up = 'PARAMVALCOUNT' then
    begin
      AToks[AIdx].OutText := 'RqParams.ValCount';
      Exit;
    end;
    if ((Up = 'PARAMSTR$') or (Up = 'PARAMVAL')) and IsOp(AToks, NextIdx, '(') and
       (MatchParen(AToks, NextIdx, ATo) > 0) then
    begin
      if Up = 'PARAMSTR$' then
        AToks[AIdx].OutText := 'RqParamStr'
      else
        AToks[AIdx].OutText := 'RqParamVal';
      AToks[NextIdx].Post := AToks[NextIdx].Post + 'RqParams, ';
      AToks[MatchParen(AToks, NextIdx, ATo)].Pre := ', __FILE__, __LINE__' +
        AToks[MatchParen(AToks, NextIdx, ATo)].Pre;
      Exit;
    end;
  end;

  // CODEPTR(процедура), CALLBACK(процедура) -> Cast(Integer, @процедура):
  // адрес процедуры FreeBASIC (stdcall) годится для Windows как есть
  if ((Up = 'CODEPTR') or (Up = 'CALLBACK')) and (FindProc(Up) = nil) and
     IsOp(AToks, NextIdx, '(') and (MatchParen(AToks, NextIdx, ATo) > 0) then
  begin
    ProcRec := nil;
    if NextSig(AToks, NextIdx + 1, ATo) >= 0 then
      ProcRec := FindProc(AToks[NextSig(AToks, NextIdx + 1, ATo)].Up);
    if (ProcRec = nil) or
       (NextSig(AToks, NextSig(AToks, NextIdx + 1, ATo) + 1, ATo) <>
        MatchParen(AToks, NextIdx, ATo)) then
      Error(AToks[AIdx].Text + RawText(AToks, NextIdx, MatchParen(AToks, NextIdx, ATo)) +
            ': ожидалось имя SUB или FUNCTION (метод своего компонента пока ' +
            'не поддержан)')
    else
    begin
      AToks[AIdx].OutText := 'Cast';
      AToks[NextIdx].Post := AToks[NextIdx].Post + 'Integer, @';
    end;
    Exit;
  end;
  // CALLFUNC(указатель, параметры) в выражении ->
  // Cast(тип процедуры, указатель)(параметры); у событий своих компонентов
  // (EVENT внутри TYPE) - как раньше (TypeCallFunc)
  if (Up = 'CALLFUNC') and (FindProc(Up) = nil) and IsOp(AToks, NextIdx, '(') and
     (MatchParen(AToks, NextIdx, ATo) > 0) then
  begin
    CallFuncExpr(AToks, AIdx, NextIdx, MatchParen(AToks, NextIdx, ATo));
    Exit;
  end;

  ProcRec := FindProc(Up);
  if ProcRec <> nil then
  begin
    AToks[AIdx].OutText := ProcRec.FbName;
    GlobalQualify(AToks, AIdx);
    // вызов FUNCTIONI / SUBI в выражении: параметры - списком RqPList
    if ProcRec.IsVariadic then
    begin
      if IsOp(AToks, NextIdx, '(') and (MatchParen(AToks, NextIdx, ATo) > 0) then
        WrapVariadicArgs(AToks, NextIdx + 1, MatchParen(AToks, NextIdx, ATo) - 1,
                         AIdx, True)
      else
        AToks[AIdx].Post := AToks[AIdx].Post + '(RqPList())';
    end;
    Exit;
  end;
  if FFuncMap.IndexOfName(Up) >= 0 then
  begin
    AToks[AIdx].OutText := FFuncMap.Values[Up];
    Exit;
  end;
  if InList(FFbStrFuncs, Up) then
  begin
    if IsOp(AToks, NextIdx, '(') then
      GlobalQualify(AToks, AIdx);
    Exit;
  end;
  if InList(FRqStrFuncs, Up) then
  begin
    WarnOnce('FN|' + Up, AToks[AIdx].Text + ': функция RapidQ пока не поддержана');
    Exit;
  end;
  // Объявленная переменная с именем слова RapidQ (параметр line в
  // RichEdPopUp.inc) - переменная
  if InList(FKeywords, Up) then
  begin
    VarRec := FindVar(Up);
    if (VarRec <> nil) and VarRec.Explicit and not VarRec.IsArray and
       not IsOp(AToks, NextIdx, '(') then
    begin
      AToks[AIdx].OutText := VarRec.FbName;
      WrapStrIndex(AToks, AIdx, ATo, VarRec);
      Exit;
    end;
  end;
  if InList(FKeywords, Up) and IsOp(AToks, NextIdx, '(') then
  begin
    // Left(...) внутри метода компонента со свойством Left
    GlobalQualify(AToks, AIdx);
    Exit;
  end;
  if InList(FKeywords, Up) or InList(FTypes, Up) or InList(FObjClasses, Up) or
     InList(FLabels, Up) then
    Exit;
  VarRec := FindVar(Up);
  if IsOp(AToks, NextIdx, '(') then
  begin
    // Массив - если объявлен массивом; иначе вызов неизвестной функции
    if (VarRec <> nil) and VarRec.IsArray then
      AToks[AIdx].OutText := VarRec.FbName
    else if VarRec = nil then
    begin
      if SuffixOf(Up) <> '' then
        WarnOnce('FN|' + Up, AToks[AIdx].Text + ': неизвестная функция');
    end
    else
      AToks[AIdx].OutText := VarRec.FbName;
    if (VarRec <> nil) and (VarRec.Scope = '') and VarRec.Explicit then
      GlobalQualify(AToks, AIdx);
    Exit;
  end;
  VarRec := ResolveVar(AToks[AIdx].Text, False);
  AToks[AIdx].OutText := VarRec.FbName;
  if (VarRec.Scope = '') and VarRec.Explicit then
    GlobalQualify(AToks, AIdx);
  WrapStrIndex(AToks, AIdx, ATo, VarRec);
  // Необъявленная переменная, которой нигде не присваивается значение, -
  // всегда 0 / "" (так RapidQ молча и работает); чаще всего опечатка:
  // REPLACESUBSTR$(s, crlfcrlf, crlf) вместо crlf+crlf
  if (FPass = 2) and not VarRec.Explicit and not VarRec.Assigned then
    WarnOnce('NA|' + VarRec.Scope + '|' + VarRec.Name, AToks[AIdx].Text +
      ': не объявлена и нигде не получает значение - в RapidQ всегда ' +
      DefaultValueText(VarRec.RqType) + ' (опечатка или объявлена в файле, которого нет?)');
end;

// Присваивание (Переменная = выражение, Объект.Свойство = выражение) или
// вызов процедуры
procedure TRqFbConv.ProcessAssignOrCall(var AToks: TToks; AFrom, ATo: Integer);
var
  FirstIdx, TokIdx, EqIdx, Depth, LhsEnd, RhsFirst, RhsLast, LastMember,
    CloseIdx: Integer;
  HasDot: Boolean;
  Up, TargetType, Conv, Display, EventKey: string;
  VarRec: TRqVar;
  ProcRec: TRqProc;
begin
  FirstIdx := NextSig(AToks, AFrom, ATo);
  if FirstIdx < 0 then
    Exit;
  // "=" на верхнем уровне
  EqIdx := -1;
  Depth := 0;
  HasDot := False;
  LastMember := -1;
  for TokIdx := FirstIdx to ATo do
  begin
    if IsOp(AToks, TokIdx, '(') then
      Inc(Depth)
    else if IsOp(AToks, TokIdx, ')') then
      Dec(Depth)
    else if (Depth = 0) and IsOp(AToks, TokIdx, '=') then
    begin
      EqIdx := TokIdx;
      Break;
    end
    else if (Depth = 0) and IsOp(AToks, TokIdx, '.') then
    begin
      HasDot := True;
      LastMember := NextSig(AToks, TokIdx + 1, ATo);
    end;
  end;

  if (EqIdx < 0) or ((AToks[FirstIdx].Kind <> tkIdent) and
                     not IsOp(AToks, FirstIdx, '.')) then
  begin
    // Вызов: Proc арг, Объект.Метод арг. Первое слово - не переменная.
    if (AToks[FirstIdx].Kind = tkIdent) and (FindVar(AToks[FirstIdx].Up) = nil) and
       not IsOp(AToks, NextSig(AToks, FirstIdx + 1, ATo), '.') then
    begin
      ProcRec := FindProc(AToks[FirstIdx].Up);
      if ProcRec <> nil then
      begin
        AToks[FirstIdx].OutText := ProcRec.FbName;
        GlobalQualify(AToks, FirstIdx);
      end
      // процедура RapidQ из rqrt.bi (EXTRACTRESOURCE)
      else if FFuncMap.IndexOfName(AToks[FirstIdx].Up) >= 0 then
        AToks[FirstIdx].OutText := FFuncMap.Values[AToks[FirstIdx].Up];
      ProcessExpr(AToks, FirstIdx + 1, ATo);
      // SUBI Имя a, b / Имя(a, b) -> Имя(RqPList().Arg(a).Arg(b))
      if (ProcRec <> nil) and ProcRec.IsVariadic then
      begin
        TokIdx := NextSig(AToks, FirstIdx + 1, ATo);
        if IsOp(AToks, TokIdx, '(') and (MatchParen(AToks, TokIdx, ATo) = PrevSig(AToks, ATo)) then
          WrapVariadicArgs(AToks, TokIdx + 1, MatchParen(AToks, TokIdx, ATo) - 1,
                           FirstIdx, True)
        else
          WrapVariadicArgs(AToks, FirstIdx + 1, ATo, FirstIdx, False);
      end;
    end
    else
    begin
      ProcessExpr(AToks, FirstIdx, ATo);
      // Объект.МетодSUBI a, b (без скобок; со скобками - в ProcessIdent)
      LastMember := -1;
      if (AToks[FirstIdx].Kind = tkIdent) and
         IsOp(AToks, NextSig(AToks, FirstIdx + 1, ATo), '.') then
        LastMember := NextSig(AToks, NextSig(AToks, FirstIdx + 1, ATo) + 1, ATo);
      RewriteMemberCall(AToks, FirstIdx, ATo);
      if (LastMember >= 0) and VariadicMember(AToks, LastMember) then
      begin
        TokIdx := NextSig(AToks, LastMember + 1, ATo);
        if (TokIdx >= 0) and not IsOp(AToks, TokIdx, '(') then
          WrapVariadicArgs(AToks, LastMember + 1, ATo, LastMember, False);
      end
      else
        SplitVariadicCall(AToks, FirstIdx, ATo);
    end;
    Exit;
  end;

  RhsFirst := NextSig(AToks, EqIdx + 1, ATo);
  RhsLast := PrevSig(AToks, ATo);
  if RhsFirst < 0 then
  begin
    ProcessExpr(AToks, FirstIdx, ATo);
    Exit;
  end;

  if HasDot then
  begin
    // This.Установщик = x, This.OnXxx = This.Метод внутри TYPE ... EXTENDS
    if (FCurType <> nil) and TypeAssign(AToks, FirstIdx, EqIdx, ATo) then
      Exit;
    // Объект.OnXxx = Процедура -> @Процедура (и Объект.WndProc)
    if (LastMember >= 0) and IsEventName(AToks[LastMember].Up) and
       (RhsFirst = RhsLast) and (AToks[RhsFirst].Kind = tkIdent) then
    begin
      if FPass = 1 then
        FHandlerProcs.Add(AToks[RhsFirst].Up);
      // Обработчик события с параметрами - типы его параметров по событию
      EventKey := HandlerEventKey(AToks, FirstIdx, LastMember);
      if FEventSigs.IndexOfName(EventKey) >= 0 then
      begin
        Up := FHandlerEvents.Values[AToks[RhsFirst].Up];
        if Up = '' then
          FHandlerEvents.Values[AToks[RhsFirst].Up] := EventKey
        else if (Up <> EventKey) and
                (FEventSigs.Values[Up] <> FEventSigs.Values[EventKey]) then
          WarnOnce('HE|' + AToks[RhsFirst].Up, AToks[RhsFirst].Text +
            ': обработчик событий ' + Up + ' и ' + EventKey +
            ' с разными параметрами - типы взяты по ' + Up);
      end;
      ProcRec := FindProc(AToks[RhsFirst].Up);
      if ProcRec <> nil then
      begin
        ProcessExpr(AToks, FirstIdx, EqIdx - 1);
        AToks[RhsFirst].OutText := '@' + ProcRec.FbName;
        Exit;
      end;
    end;
    ProcessExpr(AToks, FirstIdx, ATo);
    // Объект.Cell(c, r) = x -> Объект.SetCell(c, r, x)
    if (LastMember >= 0) and (FIndexedSet.IndexOfName(AToks[LastMember].Up) >= 0) and
       IsOp(AToks, NextSig(AToks, LastMember + 1, ATo), '(') then
    begin
      CloseIdx := MatchParen(AToks, NextSig(AToks, LastMember + 1, ATo), EqIdx - 1);
      if (CloseIdx > 0) and (PrevSig(AToks, EqIdx - 1) = CloseIdx) then
      begin
        AToks[LastMember].OutText := FIndexedSet.Values[AToks[LastMember].Up];
        AToks[CloseIdx].OutText := '';
        AToks[EqIdx].OutText := ',';
        AToks[RhsLast].Post := AToks[RhsLast].Post + ')';
      end;
    end;
    Exit;
  end;

  // Переменная (элемент массива) = выражение
  Up := AToks[FirstIdx].Up;
  Display := AToks[FirstIdx].Text;
  LhsEnd := NextSig(AToks, FirstIdx + 1, EqIdx - 1);
  TargetType := '';
  if (FCurProc <> nil) and FCurProc.IsFunc and
     ((Up = 'RESULT') or (Up = FCurProc.Name) or
      ((FCurType <> nil) and (Up = FCurMethodUp))) and (LhsEnd < 0) then
  begin
    // Возврат значения функции: Result = ... или Имя = ...
    if (Up = 'RESULT') or (FCurType <> nil) then
      AToks[FirstIdx].OutText := 'Function'
    else
      AToks[FirstIdx].OutText := FCurProc.FbName;
    TargetType := FCurProc.RetType;
  end
  else if InList(FKeywords, Up) and (FindVar(Up) = nil) then
  begin
    // MID$(s, 1, 1) = "x" и подобное - как есть
    ProcessExpr(AToks, FirstIdx + 1, ATo);
    Exit;
  end
  else
  begin
    // s$[N] = x: RapidQ не компилирует (тест пользователя 2026-10-08)
    if IsOp(AToks, LhsEnd, '[') then
    begin
      Error(Display + '[...] = ...: запись в символ строки RapidQ не допускает ' +
            '(ошибка компилятора RapidQ); MID$(s, N, 1) = x');
      Exit;
    end;
    if IsOp(AToks, LhsEnd, '(') then
    begin
      CloseIdx := MatchParen(AToks, LhsEnd, EqIdx - 1);
      VarRec := ResolveVar(Display, True);
      VarRec.Assigned := True;
      if CloseIdx > 0 then
        ProcessExpr(AToks, LhsEnd + 1, CloseIdx - 1);
    end
    else
      VarRec := ResolveVar(Display, False);
    VarRec.Assigned := True;
    AToks[FirstIdx].OutText := VarRec.FbName;
    if (VarRec.Scope = '') and VarRec.Explicit then
      GlobalQualify(AToks, FirstIdx);
    if not VarRec.IsConst then
      TargetType := VarRec.RqType;
  end;

  ProcessExpr(AToks, RhsFirst, RhsLast);
  Conv := ConvFunc(TargetType);
  if Conv = '' then
    Exit;
  if IsNumericType(TargetType) and ExprIsString(AToks, RhsFirst, RhsLast) then
    Warn(Display + ' = ' + RawText(AToks, RhsFirst, RhsLast) +
         ': строка в числовую переменную - будет 0');
  if (TargetType = 'STRING') and ExprIsNumber(AToks, RhsFirst, RhsLast) then
    Warn(Display + ' = ' + RawText(AToks, RhsFirst, RhsLast) +
         ': число в строковую переменную - будет пустая строка');
  AToks[RhsFirst].Pre := Conv + '(' + AToks[RhsFirst].Pre;
  AToks[RhsLast].Post := AToks[RhsLast].Post + ', "' +
                         StringReplace(Display, '"', '', [rfReplaceAll]) +
                         '", __FILE__, __LINE__)';
end;

// DIM / REDIM: имя[суффикс] [(размеры)] [AS тип], ...
procedure TRqFbConv.ProcessDim(var AToks: TToks; AFrom, ATo: Integer);
var
  TokIdx, NameIdx, OpenIdx, CloseIdx, AsIdx, TypeIdx, ItemEnd, Depth: Integer;
  IsRedim, Preserve, IsArray, Dynamic: Boolean;
  Items, Extra, Scope, RqType, StarLen, DimsText, ItemText, InitText: string;
  VarRec: TRqVar;
begin
  IsRedim := AToks[AFrom].Up = 'REDIM';
  TokIdx := NextSig(AToks, AFrom + 1, ATo);
  Preserve := IsWord(AToks, TokIdx, 'PRESERVE');
  if Preserve then
    TokIdx := NextSig(AToks, TokIdx + 1, ATo);
  Scope := '';
  if FCurProc <> nil then
    Scope := FCurProc.Name;
  Items := '';
  Extra := '';
  while (TokIdx >= 0) and (TokIdx <= ATo) do
  begin
    NameIdx := TokIdx;
    if AToks[NameIdx].Kind <> tkIdent then
    begin
      Warn('DIM: ожидалось имя переменной: ' + RawText(AToks, AFrom, ATo));
      Exit;
    end;
    // конец элемента - "," на верхнем уровне
    ItemEnd := ATo;
    Depth := 0;
    for TokIdx := NameIdx to ATo do
    begin
      if IsOp(AToks, TokIdx, '(') then
        Inc(Depth)
      else if IsOp(AToks, TokIdx, ')') then
        Dec(Depth)
      else if (Depth = 0) and IsOp(AToks, TokIdx, ',') then
      begin
        ItemEnd := TokIdx - 1;
        Break;
      end;
    end;
    OpenIdx := NextSig(AToks, NameIdx + 1, ItemEnd);
    IsArray := IsOp(AToks, OpenIdx, '(');
    DimsText := '';
    CloseIdx := NameIdx;
    if IsArray then
    begin
      CloseIdx := MatchParen(AToks, OpenIdx, ItemEnd);
      if CloseIdx < 0 then
        CloseIdx := ItemEnd;
      ProcessExpr(AToks, OpenIdx + 1, CloseIdx - 1);
      DimsText := RangeText(AToks, OpenIdx, CloseIdx);
    end;
    AsIdx := NextSig(AToks, CloseIdx + 1, ItemEnd);
    RqType := '';
    StarLen := '';
    InitText := '';
    if IsWord(AToks, AsIdx, 'AS') then
    begin
      TypeIdx := NextSig(AToks, AsIdx + 1, ItemEnd);
      if TypeIdx >= 0 then
      begin
        RqType := ParseType(AToks, TypeIdx, ItemEnd, StarLen);
        AsIdx := TypeIdx;
      end;
    end
    else
      AsIdx := CloseIdx;
    TokIdx := NextSig(AToks, AsIdx + 1, ItemEnd);
    if IsOp(AToks, TokIdx, '=') then
    begin
      ProcessExpr(AToks, TokIdx + 1, ItemEnd);
      InitText := ' = ' + RangeText(AToks, TokIdx + 1, ItemEnd);
    end;

    if IsRedim then
    begin
      VarRec := FindVar(AToks[NameIdx].Up);
      if VarRec = nil then
      begin
        if RqType = '' then
          RqType := SuffixType(SuffixOf(AToks[NameIdx].Up));
        VarRec := DeclareVar(AToks[NameIdx].Text, RqType, Scope, True, True,
                             False);
      end;
      if FPass = 1 then
        FRedims.Add(VarRec.Scope + '|' + VarRec.Name);
      ItemText := VarRec.FbName + DimsText;
    end
    else
    begin
      if RqType = '' then
        RqType := SuffixType(SuffixOf(AToks[NameIdx].Up));
      if InList(FGuiClasses, RqType) then
        FHasGui := True;
      VarRec := DeclareVar(AToks[NameIdx].Text, RqType, Scope, IsArray, True,
                           False);
      FixMemberClash(VarRec, Scope);
      Dynamic := IsArray and (FRedims.IndexOf(Scope + '|' + VarRec.Name) >= 0);
      if Dynamic then
      begin
        ItemText := VarRec.FbName + '()';
        Extra := Extra + ' : ReDim ' + VarRec.FbName + DimsText;
      end
      else
        ItemText := VarRec.FbName + DimsText;
      ItemText := ItemText + ' As ' + FbType(RqType);
      if StarLen <> '' then
        ItemText := ItemText + ' * ' + StarLen;
      // у FreeBASIC строку переменной длины нельзя инициализировать в Dim
      if (InitText <> '') and (RqType = 'STRING') and (StarLen = '') and
         not IsArray then
        Extra := Extra + ' : ' + VarRec.FbName + InitText
      else
        ItemText := ItemText + InitText;
    end;
    if Items <> '' then
      Items := Items + ', ';
    Items := Items + ItemText;
    TokIdx := NextSig(AToks, ItemEnd + 2, ATo);
    if ItemEnd >= ATo then
      Break;
  end;

  if IsRedim then
  begin
    if Preserve then
      Rebuild(AToks, AFrom, ATo, 'ReDim Preserve ' + Items)
    else
      Rebuild(AToks, AFrom, ATo, 'ReDim ' + Items);
  end
  else if Scope = '' then
    Rebuild(AToks, AFrom, ATo, 'Dim Shared ' + Items + Extra)
  else
    Rebuild(AToks, AFrom, ATo, 'Dim ' + Items + Extra);
end;

// DEFINT a, b = 5, c(3) = {1,2,3,4} - объявление переменных
procedure TRqFbConv.ProcessDef(var AToks: TToks; AFrom, ATo: Integer);
var
  Up, RqType, Scope, Items, ItemText, DimsText, InitText, Extra: string;
  TokIdx, NameIdx, ItemEnd, Depth, OpenIdx, CloseIdx: Integer;
  IsArray: Boolean;
  VarRec: TRqVar;
begin
  Up := AToks[AFrom].Up;
  if Up = 'DEFSTR' then
    RqType := 'STRING'
  else if Up = 'DEFDBL' then
    RqType := 'DOUBLE'
  else if Up = 'DEFSNG' then
    RqType := 'SINGLE'
  else if Up = 'DEFBYTE' then
    RqType := 'BYTE'
  else if Up = 'DEFWORD' then
    RqType := 'WORD'
  else if Up = 'DEFDWORD' then
    RqType := 'DWORD'
  else if Up = 'DEFSHORT' then
    RqType := 'SHORT'
  else
    RqType := 'LONG';
  Scope := '';
  if FCurProc <> nil then
    Scope := FCurProc.Name;
  Items := '';
  Extra := '';
  TokIdx := NextSig(AToks, AFrom + 1, ATo);
  while (TokIdx >= 0) and (TokIdx <= ATo) do
  begin
    NameIdx := TokIdx;
    ItemEnd := ATo;
    Depth := 0;
    for TokIdx := NameIdx to ATo do
    begin
      if IsOp(AToks, TokIdx, '(') or IsOp(AToks, TokIdx, '{') then
        Inc(Depth)
      else if IsOp(AToks, TokIdx, ')') or IsOp(AToks, TokIdx, '}') then
        Dec(Depth)
      else if (Depth = 0) and IsOp(AToks, TokIdx, ',') then
      begin
        ItemEnd := TokIdx - 1;
        Break;
      end;
    end;
    OpenIdx := NextSig(AToks, NameIdx + 1, ItemEnd);
    IsArray := IsOp(AToks, OpenIdx, '(');
    DimsText := '';
    CloseIdx := NameIdx;
    if IsArray then
    begin
      CloseIdx := MatchParen(AToks, OpenIdx, ItemEnd);
      if CloseIdx < 0 then
        CloseIdx := ItemEnd;
      ProcessExpr(AToks, OpenIdx + 1, CloseIdx - 1);
      DimsText := RangeText(AToks, OpenIdx, CloseIdx);
    end;
    InitText := '';
    TokIdx := NextSig(AToks, CloseIdx + 1, ItemEnd);
    if IsOp(AToks, TokIdx, '=') then
    begin
      ProcessExpr(AToks, TokIdx + 1, ItemEnd);
      InitText := ' = ' + RangeText(AToks, TokIdx + 1, ItemEnd);
    end;
    VarRec := DeclareVar(AToks[NameIdx].Text, RqType, Scope, IsArray, True, False);
    ItemText := VarRec.FbName + DimsText + ' As ' + FbType(RqType);
    // у FreeBASIC строку переменной длины нельзя инициализировать в Dim
    if (InitText <> '') and (RqType = 'STRING') and not IsArray then
      Extra := Extra + ' : ' + VarRec.FbName + InitText
    else
      ItemText := ItemText + InitText;
    if Items <> '' then
      Items := Items + ', ';
    Items := Items + ItemText;
    if ItemEnd >= ATo then
      Break;
    TokIdx := NextSig(AToks, ItemEnd + 2, ATo);
  end;
  if Scope = '' then
    Rebuild(AToks, AFrom, ATo, 'Dim Shared ' + Items + Extra)
  else
    Rebuild(AToks, AFrom, ATo, 'Dim ' + Items + Extra);
end;

// CONST Имя = значение
procedure TRqFbConv.ProcessConst(var AToks: TToks; AFrom, ATo: Integer);
var
  NameIdx, EqIdx: Integer;
  RqType, Scope: string;
  VarRec: TRqVar;
begin
  NameIdx := NextSig(AToks, AFrom + 1, ATo);
  // $define False 0 ... CONST False = 0: имя уже заменено числом. RapidQ
  // такое компилирует, False дальше - 0 (тест пользователя 2026-10-08) -
  // CONST пропускается; другое значение - предупреждение
  if (NameIdx >= 0) and (AToks[NameIdx].Kind = tkNumber) then
  begin
    EqIdx := NextSig(AToks, NameIdx + 1, ATo);
    if IsOp(AToks, EqIdx, '=') and
       (CompareText(Trim(RawText(AToks, EqIdx + 1, ATo)), AToks[NameIdx].Text) <> 0) then
      Warn('CONST ' + AToks[NameIdx].Text + ' = ' + Trim(RawText(AToks, EqIdx + 1, ATo)) +
           ': имя константы заменено $DEFINE на ' + AToks[NameIdx].Text +
           ', значение константы не используется');
    Rebuild(AToks, AFrom, ATo, '');
    Exit;
  end;
  if (NameIdx < 0) or (AToks[NameIdx].Kind <> tkIdent) then
    Exit;
  EqIdx := NextSig(AToks, NameIdx + 1, ATo);
  RqType := SuffixType(SuffixOf(AToks[NameIdx].Up));
  if (EqIdx >= 0) and ExprIsString(AToks, EqIdx + 1, ATo) then
    RqType := 'STRING';
  Scope := '';
  if FCurProc <> nil then
    Scope := FCurProc.Name;
  VarRec := DeclareVar(AToks[NameIdx].Text, RqType, Scope, False, True, True);
  AToks[NameIdx].OutText := VarRec.FbName;
  if EqIdx >= 0 then
    ProcessExpr(AToks, EqIdx + 1, ATo);
end;

// Параметры (текст FreeBASIC): [BYREF|BYVAL] имя[суффикс][()] [AS тип]
function TRqFbConv.ParseParams(var AToks: TToks; AFrom, ATo: Integer;
                               const AScope: string): string;
var
  TokIdx, ItemStart, ItemEnd, NameIdx, NextIdx, Depth, TypeIdx: Integer;
  ByRefFlag, ByValFlag, IsArray: Boolean;
  RqType, StarLen, ItemText, EventName, Sig, SigItem: string;
  VarRec: TRqVar;
  SavedProc: TRqProc;
  ParamIdx, SigCount, SigPos: Integer;
  SigList: TStringList;
  OwnInfo: TRqTypeInfo;
begin
  Result := '';
  FParamAliases := '';
  ItemStart := AFrom;
  ParamIdx := 0;
  // Обработчик события с параметрами: типы по событию (RqEventSigText)
  SigList := nil;
  EventName := FHandlerEvents.Values[UpperCase(AScope)];
  if EventName <> '' then
  begin
    SigList := TStringList.Create;
    Sig := FEventSigs.Values[EventName] + ';';
    while Sig <> '' do
    begin
      SigPos := Pos(';', Sig);
      SigItem := Copy(Sig, 1, SigPos - 1);
      Delete(Sig, 1, SigPos);
      if SigItem <> '' then
        SigList.Add(SigItem);
    end;
  end;
  SigCount := 0;
  if SigList <> nil then
    SigCount := SigList.Count;
  try
  while ItemStart <= ATo do
  begin
    ItemEnd := ATo;
    Depth := 0;
    for TokIdx := ItemStart to ATo do
    begin
      if IsOp(AToks, TokIdx, '(') then
        Inc(Depth)
      else if IsOp(AToks, TokIdx, ')') then
        Dec(Depth)
      else if (Depth = 0) and IsOp(AToks, TokIdx, ',') then
      begin
        ItemEnd := TokIdx - 1;
        Break;
      end;
    end;
    NameIdx := NextSig(AToks, ItemStart, ItemEnd);
    ByRefFlag := False;
    ByValFlag := False;
    if IsWord(AToks, NameIdx, 'BYREF') then
    begin
      ByRefFlag := True;
      NameIdx := NextSig(AToks, NameIdx + 1, ItemEnd);
    end
    else if IsWord(AToks, NameIdx, 'BYVAL') then
    begin
      ByValFlag := True;
      NameIdx := NextSig(AToks, NameIdx + 1, ItemEnd);
    end;
    if (NameIdx >= 0) and (AToks[NameIdx].Kind = tkIdent) then
    begin
      NextIdx := NextSig(AToks, NameIdx + 1, ItemEnd);
      IsArray := IsOp(AToks, NextIdx, '(');
      if IsArray then
        NextIdx := NextSig(AToks, MatchParen(AToks, NextIdx, ItemEnd) + 1, ItemEnd);
      RqType := SuffixType(SuffixOf(AToks[NameIdx].Up));
      StarLen := '';
      if IsWord(AToks, NextIdx, 'AS') then
      begin
        TypeIdx := NextSig(AToks, NextIdx + 1, ItemEnd);
        if TypeIdx >= 0 then
          RqType := ParseType(AToks, TypeIdx, ItemEnd, StarLen);
      end;
      // Параметр обработчика события: тип и ByRef/ByVal - по событию
      if (ParamIdx < SigCount) and not IsArray then
      begin
        SigItem := SigList[ParamIdx];
        if not IsObjectType(RqType) or (Copy(SigItem, 2, MaxInt) = 'QRECT') then
        begin
          RqType := Copy(SigItem, 2, MaxInt);
          ByRefFlag := SigItem[1] = 'R';
          ByValFlag := SigItem[1] = 'V';
        end;
      end;
      Inc(ParamIdx);
      SavedProc := FCurProc;
      VarRec := DeclareVar(AToks[NameIdx].Text, RqType, AScope, IsArray, True,
                           False);
      FixMemberClash(VarRec, AScope);
      FCurProc := SavedProc;
      VarRec.RqType := RqType;
      OwnInfo := FindTypeInfo(RqType);
      if IsArray then
        ItemText := VarRec.FbName + '() As ' + FbType(RqType)
      else if (OwnInfo <> nil) and InList(FHandlerProcs, UpperCase(AScope)) then
      begin
        // Sender AS свой компонент у обработчика события: событие
        // объявлено в классе RapidQ (Sender As QBUTTON) - параметр того
        // класса и ссылка своего типа на тот же объект
        ItemText := 'ByRef ' + VarRec.FbName + '_RqB As ' + OwnInfo.BaseDisplay;
        FParamAliases := FParamAliases + ' : Dim ByRef ' + VarRec.FbName +
          ' As ' + OwnInfo.Display + ' = *Cast(' + OwnInfo.Display +
          ' Ptr, Cast(Any Ptr, @' + VarRec.FbName + '_RqB))';
      end
      else if FLibParams and (RqType = 'STRING') then
        // STRING у функции DLL: RapidQ передаёт указатель на строку
        // (документация, глава 9), как ByVal As String у VB. В fbc 1.10
        // ByVal As String - сама строка (12 байт на стеке, CreateEventA@24
        // вместо @16 - проверено), поэтому ZString Ptr: String fbc
        // передаёт в него сам
        ItemText := 'ByVal ' + VarRec.FbName + ' As ZString Ptr'
      else
      begin
        if ByRefFlag or ((FByRefDefault or IsObjectType(RqType)) and
                         not ByValFlag) then
          ItemText := 'ByRef '
        else
          ItemText := 'ByVal ';
        ItemText := ItemText + VarRec.FbName + ' As ' + FbType(RqType);
      end;
      if Result <> '' then
        Result := Result + ', ';
      Result := Result + ItemText;
    end;
    ItemStart := ItemEnd + 2;
  end;
  if (SigList <> nil) and (FPass = 2) and (ParamIdx <> 0) and
     (ParamIdx <> SigCount) and (ParamIdx <> SigCount + 1) and
     (ParamIdx <> 1) then
    Warn(AScope + ': у обработчика ' + EventName + ' ' + IntToStr(ParamIdx) +
         ' параметров, ожидалось ' + IntToStr(SigCount) + ' (и Sender)');
  finally
    SigList.Free;
  end;
end;

// SUB Имя [(параметры)] / FUNCTION Имя[суффикс] [(параметры)] [AS тип]
procedure TRqFbConv.ProcessProcHeader(var AToks: TToks; AFrom, ATo: Integer);
var
  Up, Params, Header, RetType, StarLen, Locals, Aliases: string;
  NameIdx, OpenIdx, CloseIdx, AsIdx, TypeIdx, VarIdx: Integer;
  ProcRec: TRqProc;
  VarRec: TRqVar;
begin
  Up := AToks[AFrom].Up;
  NameIdx := NextSig(AToks, AFrom + 1, ATo);
  if (NameIdx < 0) or (AToks[NameIdx].Kind <> tkIdent) then
    Exit;
  ProcRec := GetProc(AToks[NameIdx].Text);
  ProcRec.IsFunc := (Up = 'FUNCTION') or (Up = 'FUNCTIONI');
  ProcRec.IsVariadic := (Up = 'SUBI') or (Up = 'FUNCTIONI');
  FCurProc := ProcRec;
  FGosubProcNum := 0;
  OpenIdx := NextSig(AToks, NameIdx + 1, ATo);
  Params := '';
  Aliases := '';
  CloseIdx := NameIdx;
  if IsOp(AToks, OpenIdx, '(') then
  begin
    CloseIdx := MatchParen(AToks, OpenIdx, ATo);
    if CloseIdx < 0 then
      CloseIdx := ATo;
    if ProcRec.IsVariadic then
      Params := VariadicParam
    else
    begin
      Params := ParseParams(AToks, OpenIdx + 1, CloseIdx - 1, ProcRec.Name);
      Aliases := FParamAliases;
      if ProcRec.Declared then
        UseDeclareParamNames(NameIdx, ProcRec, Params, Aliases);
    end;
  end
  else if ProcRec.IsVariadic then
    Params := VariadicParam
  else if ProcRec.Declared then
  begin
    Params := ProcRec.DeclParams;
    Aliases := ProcRec.DeclAliases;
  end;
  RetType := SuffixType(SuffixOf(ProcRec.Name));
  AsIdx := NextSig(AToks, CloseIdx + 1, ATo);
  if IsWord(AToks, AsIdx, 'AS') then
  begin
    TypeIdx := NextSig(AToks, AsIdx + 1, ATo);
    if TypeIdx >= 0 then
      RetType := ParseType(AToks, TypeIdx, ATo, StarLen);
  end;
  ProcRec.RetType := RetType;
  ProcRec.FbParams := Params;
  ProcRec.HasBody := True;
  if ProcRec.IsFunc then
    Header := 'Function ' + ProcRec.FbName + '(' + Params + ') As ' +
              FbType(RetType)
  else
    Header := 'Sub ' + ProcRec.FbName + '(' + Params + ')';
  // Необъявленные переменные этой SUB, которых нет в модуле, - локальные
  Locals := '';
  if FPass = 2 then
    for VarIdx := 0 to FVars.Count - 1 do
    begin
      VarRec := TRqVar(FVars.Objects[VarIdx]);
      if (VarRec.Scope = ProcRec.Name) and not VarRec.Explicit then
        Locals := Locals + ' : Dim ' + VarRec.FbName + ' As ' +
                  FbType(VarRec.RqType);
    end;
  // GOSUB/RETURN в этой SUB - свой стек возврата (у каждого вызова)
  if (FPass = 2) and (FGosubSites.IndexOfName(ProcRec.Name) >= 0) then
    Locals := Locals + ' : Dim rqgs_sp As Long : ReDim rqgs_stk(1 To 16) As Long';
  // Обход ограничения CODEPTR RapidQ (NewWndProc.inc, CallBack_N.inc):
  // тело - одной строкой, остальное до END FUNCTION пропускается
  if ProcRec.IsFunc and (CallbackShimBody(ProcRec, Params) <> '') then
  begin
    Locals := Locals + ' : ' + CallbackShimBody(ProcRec, Params);
    FSkipBody := True;
    Msg('Info', AToks[NameIdx].Text + ': переходник для CODEPTR RapidQ ' +
        '(машинный код) заменён - в FreeBASIC процедура программы сама ' +
        'годится для Windows');
  end;
  Rebuild(AToks, AFrom, ATo, Header + Aliases + Locals);
end;

// Имена параметров FreeBASIC из "ByVal Имя As Тип, ..." (верхний регистр)
function ParamNameList(const AParams: string): TStringList;
var
  Rest, Item: string;
  CommaPos, SpacePos: Integer;
begin
  Result := TStringList.Create;
  Rest := AParams + ',';
  while Rest <> '' do
  begin
    CommaPos := Pos(',', Rest);
    Item := Trim(Copy(Rest, 1, CommaPos - 1));
    Delete(Rest, 1, CommaPos);
    if Item = '' then
      Continue;
    if (UpperCase(Copy(Item, 1, 6)) = 'BYVAL ') or
       (UpperCase(Copy(Item, 1, 6)) = 'BYREF ') then
      Item := Trim(Copy(Item, 7, MaxInt));
    SpacePos := Pos(' ', Item);
    if SpacePos > 0 then
      Item := Copy(Item, 1, SpacePos - 1);
    Result.Add(UpperCase(Item));
  end;
end;

// Имена параметров в DECLARE и в заголовке SUB/FUNCTION разные: в теле
// RapidQ видит имена из DECLARE, имя из заголовка - необъявленная
// переменная (тест пользователя 2026-10-08: DECLARE SUB T (A AS LONG),
// SUB T (B AS LONG) PRINT A, B; T 5 -> 5 и 0). Заголовок FreeBASIC - с
// параметрами DECLARE, имена из заголовка - локальные переменные.
procedure TRqFbConv.UseDeclareParamNames(ANameIdx: Integer; AProc: TRqProc;
                                         var AParams, AAliases: string);
var
  DefNames, DeclNames: TStringList;
  NameIdx: Integer;
  Differ: Boolean;
  VarRec: TRqVar;
  Found: Integer;
begin
  DefNames := ParamNameList(AParams);
  DeclNames := ParamNameList(AProc.DeclParams);
  try
    if DefNames.Count <> DeclNames.Count then
      Exit;
    Differ := False;
    for NameIdx := 0 to DefNames.Count - 1 do
      if DefNames[NameIdx] <> DeclNames[NameIdx] then
        Differ := True;
    if not Differ then
      Exit;
    AParams := AProc.DeclParams;
    AAliases := AProc.DeclAliases;
    for NameIdx := 0 to DefNames.Count - 1 do
      if DeclNames.IndexOf(DefNames[NameIdx]) < 0 then
        for Found := 0 to FVars.Count - 1 do
        begin
          VarRec := TRqVar(FVars.Objects[Found]);
          if (VarRec.Scope = AProc.Name) and
             (UpperCase(VarRec.FbName) = DefNames[NameIdx]) then
            VarRec.Explicit := False;
        end;
    Warn(AProc.Name + ': имена параметров в DECLARE (' + DeclNames.CommaText +
         ') и в заголовке (' + DefNames.CommaText + ') разные - как в ' +
         'RapidQ, в теле действуют имена из DECLARE, имена из заголовка - ' +
         'необъявленные переменные (0)');
  finally
    DefNames.Free;
    DeclNames.Free;
  end;
end;

// Функции из NewWndProc.inc, CallBack_N.inc, CallBackForwarder.inc и
// rapidq2.inc строят в памяти переходник x86 к MasterCallBack_N (у RapidQ
// процедура не может быть оконной процедурой Windows напрямую). В
// FreeBASIC адрес из BIND - уже настоящая процедура stdcall: переходник
// не нужен. "" - не такая функция.
function TRqFbConv.CallbackShimBody(AProc: TRqProc; const AParams: string): string;
var
  Names: TStringList;
  Rest, Item: string;
  CommaPos, SpacePos: Integer;
begin
  Result := '';
  if (AProc.Name <> 'SETNEWWNDPROC') and (AProc.Name <> 'SETNEWFWTOCALLBACK') and
     not ((Copy(AProc.Name, 1, 13) = 'SETNEWCALLBACK') and
          (Length(AProc.Name) = 16) and (AProc.Name[15] = '_') and
          (AProc.Name[16] in ['0'..'8'])) then
    Exit;
  Names := TStringList.Create;
  try
    // имена параметров FreeBASIC: "ByVal Имя As Тип, ..."
    Rest := AParams + ',';
    while Rest <> '' do
    begin
      CommaPos := Pos(',', Rest);
      Item := Trim(Copy(Rest, 1, CommaPos - 1));
      Delete(Rest, 1, CommaPos);
      if Item = '' then
        Continue;
      if (UpperCase(Copy(Item, 1, 6)) = 'BYVAL ') or
         (UpperCase(Copy(Item, 1, 6)) = 'BYREF ') then
        Item := Trim(Copy(Item, 7, MaxInt));
      SpacePos := Pos(' ', Item);
      if SpacePos > 0 then
        Item := Copy(Item, 1, SpacePos - 1);
      Names.Add(Item);
    end;
    if (AProc.Name = 'SETNEWWNDPROC') and (Names.Count = 2) then
      Result := 'Function = RqSetWndProc(' + Names[0] + ', ' + Names[1] + ')'
    else if (AProc.Name = 'SETNEWFWTOCALLBACK') and (Names.Count = 2) then
      Result := 'Function = ' + Names[1]
    else if (Copy(AProc.Name, 1, 13) = 'SETNEWCALLBAC') and (Names.Count = 1) then
      Result := 'Function = ' + Names[0];
  finally
    Names.Free;
  end;
end;

// CALLFUNC(указатель, параметры) -> Cast(тип, Cast(Integer, указатель))(параметры)
procedure TRqFbConv.CallFuncExpr(var AToks: TToks; AIdx, AOpen, AClose: Integer);
var
  TokIdx, Depth, CommaIdx: Integer;
  ProcRec: TRqProc;
begin
  CommaIdx := -1;
  Depth := 0;
  for TokIdx := AOpen + 1 to AClose - 1 do
    if IsOp(AToks, TokIdx, '(') then
      Inc(Depth)
    else if IsOp(AToks, TokIdx, ')') then
      Dec(Depth)
    else if (Depth = 0) and IsOp(AToks, TokIdx, ',') then
    begin
      CommaIdx := TokIdx;
      Break;
    end;
  if CommaIdx > 0 then
    CallFuncTarget(AToks, AOpen + 1, CommaIdx - 1, ProcRec)
  else
    CallFuncTarget(AToks, AOpen + 1, AClose - 1, ProcRec);
  if ProcRec = nil then
  begin
    if FCurType = nil then
      Error('CALLFUNC' + RawText(AToks, AOpen, AClose) + ': переменная не ' +
            'привязана к процедуре через BIND');
    Exit;
  end;
  // указатель - через Integer: в 64 бит Long в указатель не приводится
  AToks[AIdx].OutText := 'Cast';
  AToks[AOpen].Post := AToks[AOpen].Post + ProcPtrType(ProcRec) + ', Cast(Integer, ';
  if CommaIdx > 0 then
    AToks[CommaIdx].OutText := '))('
  else
    AToks[AClose].OutText := '))()';
end;

// Тип указателя FreeBASIC на процедуру: Function(параметры) As тип
function TRqFbConv.ProcPtrType(AProc: TRqProc): string;
begin
  if AProc.IsFunc then
    Result := 'Function(' + AProc.FbParams + ') As ' + FbType(AProc.RetType)
  else
    Result := 'Sub(' + AProc.FbParams + ')';
end;

// Процедура, к которой BIND привязал переменную первого параметра CALLFUNC
// (AFrom..ATo - этот параметр). Ключ - имя переменной (у Объект.Поле -
// имя поля), массив - по имени.
function TRqFbConv.CallFuncTarget(const AToks: TToks; AFrom, ATo: Integer;
                                  out AProc: TRqProc): Boolean;
var
  TokIdx, Depth: Integer;
  KeyUp: string;
begin
  AProc := nil;
  KeyUp := '';
  Depth := 0;
  for TokIdx := AFrom to ATo do
    if IsOp(AToks, TokIdx, '(') then
      Inc(Depth)
    else if IsOp(AToks, TokIdx, ')') then
      Dec(Depth)
    else if (Depth = 0) and (AToks[TokIdx].Kind = tkIdent) then
      KeyUp := AToks[TokIdx].Up;
  if (KeyUp <> '') and (FBinds.IndexOfName(KeyUp) >= 0) then
    AProc := FindProc(FBinds.Values[KeyUp]);
  Result := AProc <> nil;
end;

// BIND переменная TO процедура -> переменная = Cast(Integer, @процедура);
// переменная запоминает процедуру - по ней CALLFUNC знает параметры
// (документация RapidQ, глава 11). Процедура без тела (только DECLARE -
// шаблон, как FuncBind_4 в CallBack_4.inc) - адреса нет, только шаблон.
procedure TRqFbConv.ProcessBind(var AToks: TToks; AFrom, ATo: Integer);
var
  TokIdx, ToIdx, NameIdx, Depth: Integer;
  KeyUp: string;
  ProcRec: TRqProc;
begin
  ToIdx := -1;
  Depth := 0;
  KeyUp := '';
  for TokIdx := AFrom + 1 to ATo do
  begin
    if IsOp(AToks, TokIdx, '(') then
      Inc(Depth)
    else if IsOp(AToks, TokIdx, ')') then
      Dec(Depth)
    else if (Depth = 0) and (IsWord(AToks, TokIdx, 'TO') or
                             IsWord(AToks, TokIdx, 'AS')) then
    begin
      ToIdx := TokIdx;
      Break;
    end
    else if (Depth = 0) and (AToks[TokIdx].Kind = tkIdent) then
      KeyUp := AToks[TokIdx].Up;
  end;
  NameIdx := -1;
  if ToIdx > 0 then
    NameIdx := NextSig(AToks, ToIdx + 1, ATo);
  if (KeyUp = '') or (NameIdx < 0) or (AToks[NameIdx].Kind <> tkIdent) then
  begin
    Error('BIND: ожидалось BIND переменная TO процедура');
    Exit;
  end;
  if IsOp(AToks, NextSig(AToks, NameIdx + 1, ATo), '.') then
  begin
    Error('BIND ... TO ' + RawText(AToks, NameIdx, ATo) + ': метод своего ' +
          'компонента как указатель на процедуру пока не поддержан');
    Exit;
  end;
  ProcRec := FindProc(AToks[NameIdx].Up);
  if ProcRec = nil then
  begin
    Error('BIND ... TO ' + AToks[NameIdx].Text + ': нет такой SUB или FUNCTION');
    Exit;
  end;
  FBinds.Values[KeyUp] := ProcRec.Name;
  AToks[AFrom].OutText := '';
  if (AFrom + 1 <= ATo) and (AToks[AFrom + 1].Kind = tkSpace) then
    AToks[AFrom + 1].OutText := '';
  ProcessExpr(AToks, AFrom + 1, ToIdx - 1);
  if ProcRec.HasBody or (FPass = 1) then
  begin
    AToks[ToIdx].OutText := '= Cast(Integer, @';
    AToks[NameIdx].OutText := ProcRec.FbName;
    GlobalQualify(AToks, NameIdx);
    AToks[NameIdx].Post := AToks[NameIdx].Post + ')';
  end
  else
  begin
    // только шаблон (у процедуры нет тела): оператор не нужен
    ClearRange(AToks, AFrom, ATo);
  end;
end;

// CALLFUNC указатель, параметры (оператор без скобок) ->
// Cast(тип процедуры, указатель)(параметры)
procedure TRqFbConv.ProcessCallFuncStmt(var AToks: TToks; AFrom, ATo: Integer);
var
  TokIdx, Depth, CommaIdx, LastIdx, ArgFrom: Integer;
  ProcRec: TRqProc;
begin
  ArgFrom := NextSig(AToks, AFrom + 1, ATo);
  LastIdx := PrevSig(AToks, ATo);
  // CALLFUNC(указатель, ...) целиком в скобках - как в выражении
  if IsOp(AToks, ArgFrom, '(') and (MatchParen(AToks, ArgFrom, ATo) = LastIdx) then
  begin
    ProcessExpr(AToks, AFrom, ATo);
    Exit;
  end;
  if ArgFrom < 0 then
  begin
    Error('CALLFUNC: нет указателя');
    Exit;
  end;
  CommaIdx := -1;
  Depth := 0;
  for TokIdx := ArgFrom to ATo do
    if IsOp(AToks, TokIdx, '(') then
      Inc(Depth)
    else if IsOp(AToks, TokIdx, ')') then
      Dec(Depth)
    else if (Depth = 0) and IsOp(AToks, TokIdx, ',') then
    begin
      CommaIdx := TokIdx;
      Break;
    end;
  if CommaIdx > 0 then
    CallFuncTarget(AToks, ArgFrom, CommaIdx - 1, ProcRec)
  else
    CallFuncTarget(AToks, ArgFrom, LastIdx, ProcRec);
  if ProcRec = nil then
  begin
    Error('CALLFUNC ' + RawText(AToks, ArgFrom, ATo) + ': переменная не ' +
          'привязана к процедуре через BIND');
    Exit;
  end;
  AToks[AFrom].OutText := 'Cast(' + ProcPtrType(ProcRec) + ', Cast(Integer,';
  if CommaIdx > 0 then
  begin
    AToks[CommaIdx].OutText := '))(';
    AToks[LastIdx].Post := AToks[LastIdx].Post + ')';
  end
  else
    AToks[LastIdx].Post := AToks[LastIdx].Post + '))()';
  ProcessExpr(AToks, ArgFrom, ATo);
end;

// DECLARE SUB|FUNCTION Имя [LIB "dll"] [ALIAS "имя"] [(параметры)] [AS тип]
procedure TRqFbConv.ProcessDeclare(var AToks: TToks; AFrom, ATo: Integer);
var
  KindIdx, NameIdx, TokIdx, OpenIdx, CloseIdx, TypeIdx: Integer;
  IsFunc: Boolean;
  LibText, AliasText, Params, RetType, StarLen, Header: string;
  ProcRec: TRqProc;
  SavedProc: TRqProc;
begin
  KindIdx := NextSig(AToks, AFrom + 1, ATo);
  if not (IsWord(AToks, KindIdx, 'SUB') or IsWord(AToks, KindIdx, 'FUNCTION') or
          IsWord(AToks, KindIdx, 'SUBI') or IsWord(AToks, KindIdx, 'FUNCTIONI')) then
  begin
    Warn('DECLARE ' + RawText(AToks, KindIdx, KindIdx) + ': не поддержано');
    Exit;
  end;
  IsFunc := IsWord(AToks, KindIdx, 'FUNCTION') or IsWord(AToks, KindIdx, 'FUNCTIONI');
  NameIdx := NextSig(AToks, KindIdx + 1, ATo);
  if (NameIdx < 0) or (AToks[NameIdx].Kind <> tkIdent) then
    Exit;
  ProcRec := GetProc(AToks[NameIdx].Text);
  ProcRec.IsFunc := IsFunc;
  ProcRec.IsVariadic := IsWord(AToks, KindIdx, 'SUBI') or IsWord(AToks, KindIdx, 'FUNCTIONI');
  ProcRec.Declared := True;
  LibText := '';
  AliasText := '';
  TokIdx := NextSig(AToks, NameIdx + 1, ATo);
  if IsWord(AToks, TokIdx, 'LIB') then
  begin
    TokIdx := NextSig(AToks, TokIdx + 1, ATo);
    if TokIdx >= 0 then
      LibText := ' Lib ' + AToks[TokIdx].Text;
    TokIdx := NextSig(AToks, TokIdx + 1, ATo);
  end;
  if IsWord(AToks, TokIdx, 'ALIAS') then
  begin
    TokIdx := NextSig(AToks, TokIdx + 1, ATo);
    if TokIdx >= 0 then
      AliasText := ' Alias ' + AToks[TokIdx].Text;
    TokIdx := NextSig(AToks, TokIdx + 1, ATo);
  end;
  Params := '';
  FParamAliases := '';
  OpenIdx := TokIdx;
  CloseIdx := TokIdx - 1;
  if IsOp(AToks, OpenIdx, '(') then
  begin
    CloseIdx := MatchParen(AToks, OpenIdx, ATo);
    if CloseIdx < 0 then
      CloseIdx := ATo;
    SavedProc := FCurProc;
    FLibParams := LibText <> '';
    try
      if ProcRec.IsVariadic then
        Params := VariadicParam
      else
        Params := ParseParams(AToks, OpenIdx + 1, CloseIdx - 1, ProcRec.Name);
    finally
      FLibParams := False;
    end;
    FCurProc := SavedProc;
  end
  else if ProcRec.IsVariadic then
    Params := VariadicParam;
  ProcRec.DeclParams := Params;
  ProcRec.DeclAliases := FParamAliases;
  ProcRec.FbParams := Params;
  if LibText <> '' then
    ProcRec.HasBody := True;
  RetType := SuffixType(SuffixOf(ProcRec.Name));
  TokIdx := NextSig(AToks, CloseIdx + 1, ATo);
  if IsWord(AToks, TokIdx, 'AS') then
  begin
    TypeIdx := NextSig(AToks, TokIdx + 1, ATo);
    if TypeIdx >= 0 then
      RetType := ParseType(AToks, TypeIdx, ATo, StarLen);
  end;
  ProcRec.RetType := RetType;
  if IsFunc then
    Header := 'Declare Function ' + ProcRec.FbName + LibText + AliasText +
              '(' + Params + ') As ' + FbType(RetType)
  else
    Header := 'Declare Sub ' + ProcRec.FbName + LibText + AliasText +
              '(' + Params + ')';
  Rebuild(AToks, AFrom, ATo, Header);
end;

// TYPE Имя [EXTENDS Класс]. Свой компонент (EXTENDS; TYPE Имя AS Класс в
// главе 10.5 документации - то же): Type FreeBASIC целиком, со всеми
// полями и Declare методов (собраны в первом проходе), выводится здесь;
// после него #line возвращает номера строк исходника.
procedure TRqFbConv.ProcessTypeHeader(var AToks: TToks; AFrom, ATo: Integer);
var
  NameIdx, ExtIdx, BaseIdx, LineIdx, Found: Integer;
  Info: TRqTypeInfo;
  Block: string;
begin
  NameIdx := NextSig(AToks, AFrom + 1, ATo);
  if (NameIdx < 0) or (AToks[NameIdx].Kind <> tkIdent) then
    Exit;
  FTypes.Add(AToks[NameIdx].Up);
  ExtIdx := NextSig(AToks, NameIdx + 1, ATo);
  BaseIdx := NextSig(AToks, ExtIdx + 1, ATo);
  if IsOp(AToks, ExtIdx, '<') then
  begin
    Warn('TYPE ' + AToks[NameIdx].Text + '<...>: шаблоны TYPE пока не ' +
         'поддержаны, текст оставлен как есть');
    FPlainType := '';
    FInType := True;
    Exit;
  end;
  if not ((IsWord(AToks, ExtIdx, 'EXTENDS') or IsWord(AToks, ExtIdx, 'AS')) and
          (BaseIdx >= 0) and (AToks[BaseIdx].Kind = tkIdent)) then
  begin
    // запись RapidQ - поля подряд, без выравнивания (тест пользователя
    // 2026-10-08: TYPE с STRING*5 и INTEGER - SIZEOF 9)
    FPlainType := AToks[NameIdx].OutText;
    FFixBodies := '';
    AToks[NameIdx].OutText := AToks[NameIdx].OutText + ' Field = 1';
    FInType := True;
    Exit;
  end;
  if FPass = 1 then
  begin
    if FTypeInfos.Find(AToks[NameIdx].Up, Found) then
    begin
      Info := TRqTypeInfo(FTypeInfos.Objects[Found]);
      Info.Free;
      FTypeInfos.Delete(Found);
    end;
    Info := TRqTypeInfo.Create;
    Info.Name := AToks[NameIdx].Up;
    Info.Display := AToks[NameIdx].Text;
    Info.BaseClass := AToks[BaseIdx].Up;
    Info.BaseDisplay := AToks[BaseIdx].Text;
    FTypeInfos.AddObject(Info.Name, Info);
    if InList(FGuiClasses, Info.BaseClass) then
      FGuiClasses.Add(Info.Name);
  end
  else
    Info := FindTypeInfo(AToks[NameIdx].Up);
  if Info = nil then
    Exit;
  FCurType := Info;
  FTypeBody := 0;
  FTypeWith := '';
  FCurMethodUp := '';
  if FPass <> 2 then
    Exit;
  Block := '';
  for LineIdx := 0 to Info.Before.Count - 1 do
    Block := Block + Info.Before[LineIdx] + CrLf;
  Block := Block + 'Type ' + Info.Display + ' Extends ' + Info.BaseDisplay + CrLf;
  for LineIdx := 0 to Info.Decls.Count - 1 do
    Block := Block + '    ' + Info.Decls[LineIdx] + CrLf;
  if Info.HasCtor or (Info.Regs <> '') then
    Block := Block + '    Declare Constructor()' + CrLf;
  Block := Block + 'End Type' + CrLf;
  for LineIdx := 0 to Info.After.Count - 1 do
    Block := Block + Info.After[LineIdx] + CrLf;
  Block := Block + '#line ' + IntToStr(FCurLine + FLineBreaks) + ' "' +
           FCurFile + '"';
  // строка целиком (и комментарий: после #line его не должно быть)
  ClearRange(AToks, AFrom, High(AToks));
  FLostLines := 0;
  AToks[AFrom].OutText := Block;
end;

// Поле TYPE: имя [(размеры)] AS тип
procedure TRqFbConv.ProcessField(var AToks: TToks; AFrom, ATo: Integer);
var
  NameIdx, OpenIdx, CloseIdx, AsIdx, TypeIdx: Integer;
  RqType, StarLen: string;
begin
  NameIdx := NextSig(AToks, AFrom, ATo);
  if (NameIdx < 0) or (AToks[NameIdx].Kind <> tkIdent) then
    Exit;
  if SuffixOf(AToks[NameIdx].Up) <> '' then
  begin
    Warn(AToks[NameIdx].Text + ': суффикс у поля TYPE не поддержан');
    AToks[NameIdx].OutText := Mangle(AToks[NameIdx].Text);
  end;
  OpenIdx := NextSig(AToks, NameIdx + 1, ATo);
  CloseIdx := NameIdx;
  if IsOp(AToks, OpenIdx, '(') then
  begin
    CloseIdx := MatchParen(AToks, OpenIdx, ATo);
    if CloseIdx < 0 then
      Exit;
    ProcessExpr(AToks, OpenIdx + 1, CloseIdx - 1);
  end
  else
    OpenIdx := -1;
  AsIdx := NextSig(AToks, CloseIdx + 1, ATo);
  if IsWord(AToks, AsIdx, 'AS') then
  begin
    AToks[AsIdx].OutText := 'As';
    TypeIdx := NextSig(AToks, AsIdx + 1, ATo);
    if TypeIdx >= 0 then
    begin
      RqType := ParseType(AToks, TypeIdx, ATo, StarLen);
      AToks[NextSig(AToks, AsIdx + 1, ATo)].OutText := FbType(RqType);
      if (RqType = 'STRING') and (StarLen <> '') and (FPlainType <> '') then
        FixedStringField(AToks, AFrom, ATo, NameIdx, OpenIdx, CloseIdx, StarLen);
    end;
  end
  else
    AToks[CloseIdx].Post := ' As ' + FbType(SuffixType(SuffixOf(AToks[NameIdx].Up)));
end;

// Поле записи STRING*N: у RapidQ - ровно N байт (тест пользователя
// 2026-10-08: SIZEOF 9 у STRING*5 + INTEGER), запись дополняется
// пробелами и обрезается до N, чтение даёт все N символов. У FreeBASIC
// String*N - N + 1 байт, поэтому поле - N байт (Имя_rqfix) и свойство Имя
// (RqFixGet / RqFixSet в rqrt.bi); тела свойств - после END TYPE.
// Массив таких полей (одно измерение) - свойство с номером.
procedure TRqFbConv.FixedStringField(var AToks: TToks; AFrom, ATo, ANameIdx,
  AOpenIdx, ACloseIdx: Integer; const AStarLen: string);
var
  FieldName, StoreName, LowText, HighText, CountText, DimText: string;
  TokIdx, Depth, ToIdx: Integer;
  SavedLost: Integer;
begin
  FieldName := AToks[ANameIdx].OutText;
  StoreName := FieldName + '_rqfix';
  if AOpenIdx < 0 then
  begin
    Rebuild(AToks, AFrom, ATo, StoreName + '(0 To ' + AStarLen +
      ' - 1) As UByte : Declare Property ' + FieldName +
      '() As String : Declare Property ' + FieldName + '(ByRef Value As String)');
    FFixBodies := FFixBodies + ' : Property ' + FPlainType + '.' + FieldName +
      '() As String : Return RqFixGet(@' + StoreName + '(0), ' + AStarLen +
      ') : End Property : Property ' + FPlainType + '.' + FieldName +
      '(ByRef Value As String) : RqFixSet(@' + StoreName + '(0), ' + AStarLen +
      ', Value) : End Property';
    Exit;
  end;
  // границы массива: (hi) или (lo TO hi); несколько измерений - как было
  Depth := 0;
  ToIdx := -1;
  for TokIdx := AOpenIdx + 1 to ACloseIdx - 1 do
  begin
    if IsOp(AToks, TokIdx, '(') then
      Inc(Depth)
    else if IsOp(AToks, TokIdx, ')') then
      Dec(Depth)
    else if (Depth = 0) and IsOp(AToks, TokIdx, ',') then
    begin
      Warn(AToks[ANameIdx].Text + ': массив STRING*N в TYPE с несколькими ' +
           'измерениями - String*N FreeBASIC (на байт длиннее)');
      Exit;
    end
    else if (Depth = 0) and IsWord(AToks, TokIdx, 'TO') then
      ToIdx := TokIdx;
  end;
  SavedLost := FLostLines;
  if ToIdx >= 0 then
  begin
    LowText := RangeText(AToks, AOpenIdx + 1, ToIdx - 1);
    HighText := RangeText(AToks, ToIdx + 1, ACloseIdx - 1);
  end
  else
  begin
    LowText := '0';
    HighText := RangeText(AToks, AOpenIdx + 1, ACloseIdx - 1);
  end;
  FLostLines := SavedLost;
  CountText := '((' + HighText + ') - (' + LowText + ') + 1)';
  DimText := '(RqFixIdx - (' + LowText + ')) * ' + AStarLen;
  Rebuild(AToks, AFrom, ATo, StoreName + '(0 To ' + CountText + ' * ' +
    AStarLen + ' - 1) As UByte : Declare Property ' + FieldName +
    '(ByVal RqFixIdx As Long) As String : Declare Property ' + FieldName +
    '(ByVal RqFixIdx As Long, ByRef Value As String)');
  FFixBodies := FFixBodies + ' : Property ' + FPlainType + '.' + FieldName +
    '(ByVal RqFixIdx As Long) As String : Return RqFixGet(@' + StoreName +
    '(' + DimText + '), ' + AStarLen + ') : End Property : Property ' +
    FPlainType + '.' + FieldName +
    '(ByVal RqFixIdx As Long, ByRef Value As String) : RqFixSet(@' + StoreName +
    '(' + DimText + '), ' + AStarLen + ', Value) : End Property';
end;

// PRINT элементы: каждый - RqFmt(...), "," -> ";"
procedure TRqFbConv.ProcessPrint(var AToks: TToks; AFrom, ATo: Integer);
var
  TokIdx, ItemStart, ItemFirst, ItemLast, Depth, CommaIdx: Integer;

  procedure FlushItem(AEnd: Integer);
  begin
    ItemFirst := NextSig(AToks, ItemStart, AEnd);
    if (ItemFirst < 0) or (ItemFirst > AEnd) then
      Exit;
    ItemLast := PrevSig(AToks, AEnd);
    ProcessExpr(AToks, ItemFirst, ItemLast);
    if IsWord(AToks, ItemFirst, 'TAB') or IsWord(AToks, ItemFirst, 'SPC') then
      Exit;
    AToks[ItemFirst].Pre := 'RqFmt(' + AToks[ItemFirst].Pre;
    AToks[ItemLast].Post := AToks[ItemLast].Post + ')';
  end;

begin
  AToks[AFrom].OutText := 'Print';
  // у компонента свой метод Print (QDebug) - оператор FreeBASIC через ..
  if (FCurType <> nil) and (FCurType.Kind('PRINT') <> #0) then
    AToks[AFrom].OutText := '..Print';
  // print"x" - у FreeBASIC нужен пробел после Print
  if (AFrom + 1 <= High(AToks)) and (AToks[AFrom + 1].Kind <> tkSpace) then
    AToks[AFrom].Post := ' ';
  ItemStart := AFrom + 1;
  TokIdx := NextSig(AToks, ItemStart, ATo);
  if TokIdx < 0 then
    Exit;
  if IsOp(AToks, TokIdx, '#') then
  begin
    // PRINT #n, ...
    CommaIdx := TokIdx;
    while (CommaIdx <= ATo) and not IsOp(AToks, CommaIdx, ',') do
      Inc(CommaIdx);
    ProcessExpr(AToks, TokIdx + 1, CommaIdx - 1);
    ItemStart := CommaIdx + 1;
  end;
  if IsWord(AToks, NextSig(AToks, ItemStart, ATo), 'USING') then
  begin
    WarnOnce('USING', 'PRINT USING пока не поддержан');
    ProcessExpr(AToks, ItemStart, ATo);
    Exit;
  end;
  Depth := 0;
  for TokIdx := ItemStart to ATo do
  begin
    if IsOp(AToks, TokIdx, '(') then
      Inc(Depth)
    else if IsOp(AToks, TokIdx, ')') then
      Dec(Depth)
    else if (Depth = 0) and (IsOp(AToks, TokIdx, ';') or IsOp(AToks, TokIdx, ',')) then
    begin
      FlushItem(TokIdx - 1);
      AToks[TokIdx].OutText := ';';
      ItemStart := TokIdx + 1;
    end;
  end;
  FlushItem(ATo);
end;

// IF усл THEN [оператор [ELSE оператор]]
procedure TRqFbConv.ProcessIf(var AToks: TToks; AFrom, ATo: Integer);
var
  TokIdx, ThenIdx, ElseIdx, Depth: Integer;
begin
  ThenIdx := -1;
  Depth := 0;
  for TokIdx := AFrom + 1 to ATo do
  begin
    if IsOp(AToks, TokIdx, '(') then
      Inc(Depth)
    else if IsOp(AToks, TokIdx, ')') then
      Dec(Depth)
    else if (Depth = 0) and IsWord(AToks, TokIdx, 'THEN') then
    begin
      ThenIdx := TokIdx;
      Break;
    end;
  end;
  if ThenIdx < 0 then
  begin
    ProcessExpr(AToks, AFrom + 1, ATo);
    Exit;
  end;
  ProcessExpr(AToks, AFrom + 1, ThenIdx - 1);
  if NextSig(AToks, ThenIdx + 1, ATo) < 0 then
    Exit;
  FInlineIf := True;
  ElseIdx := -1;
  for TokIdx := ThenIdx + 1 to ATo do
    if IsWord(AToks, TokIdx, 'ELSE') then
    begin
      ElseIdx := TokIdx;
      Break;
    end;
  if ElseIdx < 0 then
    ProcessStatement(AToks, ThenIdx + 1, ATo)
  else
  begin
    ProcessStatement(AToks, ThenIdx + 1, ElseIdx - 1);
    ProcessStatement(AToks, ElseIdx + 1, ATo);
  end;
end;

// FOR перем = a TO b [STEP c]: переменная цикла - без преобразования
procedure TRqFbConv.ProcessFor(var AToks: TToks; AFrom, ATo: Integer);
var
  VarIdx: Integer;
  VarRec: TRqVar;
begin
  VarIdx := NextSig(AToks, AFrom + 1, ATo);
  if (VarIdx >= 0) and (AToks[VarIdx].Kind = tkIdent) then
  begin
    VarRec := ResolveVar(AToks[VarIdx].Text, False);
    VarRec.Assigned := True;
    AToks[VarIdx].OutText := VarRec.FbName;
    ProcessExpr(AToks, VarIdx + 1, ATo);
  end
  else
    ProcessExpr(AToks, AFrom + 1, ATo);
end;

// GOSUB/RETURN. В FreeBASIC -lang fb GOSUB нет; переход и возврат - через
// Goto и стек номеров (RqGosubPush/RqGosubPop в rqrt.bi):
//   GOSUB Метка -> RqGosubPush(стек(), вершина, N): Goto Метка
//                  (новая строка) rqgs_retN:
//   RETURN      -> On RqGosubPop(стек(), вершина, __FILE__, __LINE__)
//                  Goto rqgs_ret1, rqgs_ret2, ...
// Стек свой у модуля (rqgs_mstk, Dim Shared в заголовке главного файла) и
// у каждой SUB/FUNCTION (rqgs_stk, локальный - в рекурсии у каждого вызова
// свой). Метка возврата - на отдельной строке, перед ней #line, чтобы
// номера строк исходника RapidQ не сдвинулись. Первый проход считает GOSUB
// в каждой области (FGosubSites), второй - нумерует их в том же порядке.

// Область GOSUB: '*' - модуль, иначе имя SUB/FUNCTION
function TRqFbConv.GosubScope: string;
begin
  if FCurProc = nil then
    Result := '*'
  else
    Result := FCurProc.Name;
end;

procedure TRqFbConv.GosubVarNames(const AScope: string; var ASpName, AStkName: string);
begin
  if AScope = '*' then
  begin
    ASpName := 'rqgs_msp';
    AStkName := 'rqgs_mstk';
  end
  else
  begin
    ASpName := 'rqgs_sp';
    AStkName := 'rqgs_stk';
  end;
end;

procedure TRqFbConv.ProcessGosub(var AToks: TToks; AFrom, ATo: Integer);
var
  LabelIdx, AfterIdx, TokIdx, SiteNum, LineNum: Integer;
  Scope, SpName, StkName, RetLabel: string;
begin
  LabelIdx := NextSig(AToks, AFrom + 1, ATo);
  if (LabelIdx < 0) or not (AToks[LabelIdx].Kind in [tkIdent, tkNumber]) then
  begin
    Error('GOSUB: нет метки');
    Exit;
  end;
  if NextSig(AToks, LabelIdx + 1, ATo) >= 0 then
  begin
    Error('GOSUB ' + AToks[LabelIdx].Text + ': после метки лишний текст');
    Exit;
  end;
  Scope := GosubScope;
  if Scope = '*' then
  begin
    Inc(FGosubModNum);
    SiteNum := FGosubModNum;
  end
  else
  begin
    Inc(FGosubProcNum);
    SiteNum := FGosubProcNum;
  end;
  if FPass = 1 then
  begin
    FGosubSites.Values[Scope] := IntToStr(SiteNum);
    Exit;
  end;

  // Что в строке после GOSUB (комментарий не в счёт)
  AfterIdx := NextSig(AToks, ATo + 1, High(AToks));
  if (AfterIdx >= 0) and (AToks[AfterIdx].Kind = tkComment) then
    AfterIdx := -1;
  // Метка возврата встаёт в начало следующей строки: в однострочном IF
  // то, что после GOSUB, оказалось бы вне IF
  if FInlineIf and (AfterIdx >= 0) then
  begin
    Error('GOSUB в однострочном IF не последним оператором (после него ' +
          AToks[AfterIdx].Text + ') пока не поддержан: замените на ' +
          'IF ... END IF');
    Exit;
  end;

  GosubVarNames(Scope, SpName, StkName);
  // Строка исходника, где стоит метка GOSUB (у строки с продолжениями " _"
  // - не первая)
  LineNum := FCurLine;
  for TokIdx := 0 to LabelIdx do
    Inc(LineNum, CountLineBreaks(AToks[TokIdx].Text));
  RetLabel := 'rqgs_ret' + IntToStr(SiteNum);
  AToks[AFrom].OutText := 'RqGosubPush(' + StkName + '(), ' + SpName + ', ' +
                          IntToStr(SiteNum) + '): Goto';
  AToks[LabelIdx].Post := AToks[LabelIdx].Post + CrLf + '#line ' +
                          IntToStr(LineNum - 1) + ' "' + FCurFile + '"' +
                          CrLf + RetLabel + ':';
  // Следующий оператор через ":" - сразу после метки возврата
  if (AfterIdx >= 0) and IsOp(AToks, AfterIdx, ':') then
    AToks[AfterIdx].OutText := '';
end;

procedure TRqFbConv.ProcessReturn(var AToks: TToks; AFrom, ATo: Integer);
var
  Scope, SpName, StkName, Targets: string;
  SiteCount, SiteIdx: Integer;
begin
  Scope := GosubScope;
  if FPass = 1 then
  begin
    if FGosubSites.IndexOfName(Scope) < 0 then
      FGosubSites.Values[Scope] := '0';
    Exit;
  end;
  if NextSig(AToks, AFrom + 1, ATo) >= 0 then
  begin
    Error('RETURN с меткой или значением пока не поддержан');
    Exit;
  end;
  GosubVarNames(Scope, SpName, StkName);
  SiteCount := StrToIntDef(FGosubSites.Values[Scope], 0);
  if SiteCount = 0 then
  begin
    if Scope = '*' then
      Warn('RETURN, а GOSUB на уровне модуля нет')
    else
      Warn('RETURN, а GOSUB в ' + FCurProc.Name + ' нет');
    AToks[AFrom].OutText := 'RqGosubPop(' + StkName + '(), ' + SpName +
                            ', __FILE__, __LINE__)';
    Exit;
  end;
  Targets := '';
  for SiteIdx := 1 to SiteCount do
  begin
    if SiteIdx > 1 then
      Targets := Targets + ', ';
    Targets := Targets + 'rqgs_ret' + IntToStr(SiteIdx);
  end;
  AToks[AFrom].OutText := 'On RqGosubPop(' + StkName + '(), ' + SpName +
                          ', __FILE__, __LINE__) Goto ' + Targets;
end;

// Параметры вызова SUBI / FUNCTIONI AFrom..ATo -> RqPList().Arg(a).Arg(b)...
// (AInParens - в скобках после имени ANameIdx; иначе скобки добавляются)
procedure TRqFbConv.WrapVariadicArgs(var AToks: TToks; AFrom, ATo, ANameIdx: Integer;
                                     AInParens: Boolean);
var
  ArgFirst, ArgLast, TokIdx, Depth: Integer;
begin
  ArgFirst := NextSig(AToks, AFrom, ATo);
  if ArgFirst < 0 then
  begin
    if AInParens then
      AToks[AFrom - 1].Post := AToks[AFrom - 1].Post + 'RqPList()'
    else
      AToks[ANameIdx].Post := AToks[ANameIdx].Post + '(RqPList())';
    Exit;
  end;
  ArgLast := PrevSig(AToks, ATo);
  AToks[ArgFirst].Pre := 'RqPList().Arg(' + AToks[ArgFirst].Pre;
  Depth := 0;
  for TokIdx := ArgFirst to ArgLast do
  begin
    if IsOp(AToks, TokIdx, '(') then
      Inc(Depth)
    else if IsOp(AToks, TokIdx, ')') then
      Dec(Depth)
    else if (Depth = 0) and IsOp(AToks, TokIdx, ',') then
      AToks[TokIdx].OutText := ').Arg(';
  end;
  AToks[ArgLast].Post := AToks[ArgLast].Post + ')';
  if not AInParens then
  begin
    AToks[ANameIdx].Post := AToks[ANameIdx].Post + '(';
    AToks[ArgLast].Post := AToks[ArgLast].Post + ')';
  end;
end;

// Член AMemberIdx (после ".") - метод SUBI / FUNCTIONI своего компонента:
// объект - This (внутри TYPE) или переменная своего компонента
function TRqFbConv.VariadicMember(const AToks: TToks; AMemberIdx: Integer): Boolean;
var
  DotIdx, ObjIdx: Integer;
  Info: TRqTypeInfo;
  VarRec: TRqVar;
begin
  Result := False;
  if (AMemberIdx < 0) or (AToks[AMemberIdx].Kind <> tkIdent) then
    Exit;
  DotIdx := PrevSig(AToks, AMemberIdx - 1);
  if not IsOp(AToks, DotIdx, '.') then
    Exit;
  ObjIdx := PrevSig(AToks, DotIdx - 1);
  if (ObjIdx < 0) or (AToks[ObjIdx].Kind <> tkIdent) then
    Exit;
  // объект - сам, без "." перед ним (A.B.Метод не разбирается)
  if IsOp(AToks, PrevSig(AToks, ObjIdx - 1), '.') then
    Exit;
  Info := nil;
  if (AToks[ObjIdx].Up = 'THIS') and (FCurType <> nil) then
    Info := FCurType
  else
  begin
    VarRec := FindVar(AToks[ObjIdx].Up);
    if VarRec <> nil then
      Info := FindTypeInfo(VarRec.RqType);
  end;
  Result := (Info <> nil) and (Info.Variadic.IndexOf(AToks[AMemberIdx].Up) >= 0);
end;

// Оператор-вызов метода, у которого в FreeBASIC другие параметры:
// - Поток.WriteUDT(x) / ReadUDT(x) -> (@x, SizeOf(x)): адрес и размер
//   записи;
// - Поток.SaveArray(A(), n) / LoadArray(A(), n) -> A(LBound(A)): первый
//   параметр - элемент, с которого пишется массив (тип элемента выбирает
//   перегрузку); A(i) остаётся как есть;
// - Image.Center без параметров (QIMAGE) -> Image.CenterImage: у типа
//   FreeBASIC Center - свойство
procedure TRqFbConv.RewriteMemberCall(var AToks: TToks; AFirst, ATo: Integer);
var
  TokIdx, Depth, LastMember, ArgsFrom, ArgsTo, CloseIdx, CommaIdx, NameIdx,
    OpenIdx, ObjIdx, SavedLost: Integer;
  MemberUp, FirstArg: string;
  VarRec: TRqVar;
begin
  LastMember := -1;
  Depth := 0;
  for TokIdx := AFirst to ATo do
  begin
    if IsOp(AToks, TokIdx, '(') then
      Inc(Depth)
    else if IsOp(AToks, TokIdx, ')') then
      Dec(Depth)
    else if (Depth = 0) and IsOp(AToks, TokIdx, '.') then
      LastMember := NextSig(AToks, TokIdx + 1, ATo)
    else if (Depth = 0) and (TokIdx > LastMember) and (LastMember >= 0) and
            (AToks[TokIdx].Kind <> tkSpace) then
      Break;
  end;
  if (LastMember < 0) or (AToks[LastMember].Kind <> tkIdent) then
    Exit;
  MemberUp := AToks[LastMember].Up;
  ArgsFrom := NextSig(AToks, LastMember + 1, ATo);
  if MemberUp = 'CENTER' then
  begin
    ObjIdx := PrevSig(AToks, PrevSig(AToks, LastMember - 1) - 1);
    if (ArgsFrom >= 0) or (ObjIdx < 0) or (AToks[ObjIdx].Kind <> tkIdent) then
      Exit;
    VarRec := FindVar(AToks[ObjIdx].Up);
    if (VarRec <> nil) and (UpperCase(VarRec.RqType) = 'QIMAGE') then
      AToks[LastMember].OutText := 'CenterImage';
    Exit;
  end;
  if (MemberUp <> 'WRITEUDT') and (MemberUp <> 'READUDT') and
     (MemberUp <> 'SAVEARRAY') and (MemberUp <> 'LOADARRAY') then
    Exit;
  if ArgsFrom < 0 then
    Exit;
  ArgsTo := PrevSig(AToks, ATo);
  if IsOp(AToks, ArgsFrom, '(') then
  begin
    CloseIdx := MatchParen(AToks, ArgsFrom, ATo);
    if (CloseIdx > 0) and (CloseIdx = ArgsTo) then
    begin
      ArgsFrom := NextSig(AToks, ArgsFrom + 1, ATo);
      ArgsTo := PrevSig(AToks, CloseIdx - 1);
    end;
  end;
  if (ArgsFrom < 0) or (ArgsTo < ArgsFrom) then
    Exit;
  CommaIdx := ArgsTo + 1;
  Depth := 0;
  for TokIdx := ArgsFrom to ArgsTo do
  begin
    if IsOp(AToks, TokIdx, '(') then
      Inc(Depth)
    else if IsOp(AToks, TokIdx, ')') then
      Dec(Depth)
    else if (Depth = 0) and IsOp(AToks, TokIdx, ',') then
    begin
      CommaIdx := TokIdx;
      Break;
    end;
  end;
  if (MemberUp = 'WRITEUDT') or (MemberUp = 'READUDT') then
  begin
    if CommaIdx <= ArgsTo then
      Exit;
    SavedLost := FLostLines;
    FirstArg := RangeText(AToks, ArgsFrom, ArgsTo);
    FLostLines := SavedLost;
    AToks[ArgsFrom].OutText := '@' + AToks[ArgsFrom].OutText;
    AToks[ArgsTo].OutText := AToks[ArgsTo].OutText + ', SizeOf(' + FirstArg + ')';
    Exit;
  end;
  // A() -> A(LBound(A))
  NameIdx := ArgsFrom;
  OpenIdx := NextSig(AToks, NameIdx + 1, CommaIdx - 1);
  if (AToks[NameIdx].Kind <> tkIdent) or not IsOp(AToks, OpenIdx, '(') then
    Exit;
  CloseIdx := NextSig(AToks, OpenIdx + 1, CommaIdx - 1);
  if not IsOp(AToks, CloseIdx, ')') or
     (NextSig(AToks, CloseIdx + 1, CommaIdx - 1) >= 0) then
    Exit;
  AToks[OpenIdx].OutText := '(LBound(' + AToks[NameIdx].OutText + ')';
end;

// Объект.AddItems a, b, c, d, e... - у методов rqlcl.bi с переменным
// числом параметров перегрузки только до 4 (меню, номера) или 6 (строки) -
// вызов делится на несколько по 4 параметра (AddItems, AddTabs,
// AddPanels, AddColumns, DelItems, Add/DelStyles, Add/DelOptions)
procedure TRqFbConv.SplitVariadicCall(var AToks: TToks; AFirst, ATo: Integer);
const
  ChunkSize = 4;
var
  TokIdx, Depth, LastMember, ArgsFrom, ArgsTo, OpenIdx, CloseIdx,
    ArgStart, ArgCount: Integer;
  ObjText, CallText, ChunkText: string;
  Args: TStringList;
begin
  LastMember := -1;
  Depth := 0;
  for TokIdx := AFirst to ATo do
  begin
    if IsOp(AToks, TokIdx, '(') then
      Inc(Depth)
    else if IsOp(AToks, TokIdx, ')') then
      Dec(Depth)
    else if (Depth = 0) and IsOp(AToks, TokIdx, '.') then
      LastMember := NextSig(AToks, TokIdx + 1, ATo)
    else if (Depth = 0) and (TokIdx > LastMember) and (LastMember >= 0) and
            (AToks[TokIdx].Kind <> tkSpace) then
      Break;
  end;
  if (LastMember < 0) or (AToks[LastMember].Kind <> tkIdent) then
    Exit;
  if Pos(' ' + AToks[LastMember].Up + ' ', ' ADDITEMS ADDTABS ADDPANELS ' +
         'ADDCOLUMNS DELITEMS ADDSTYLES DELSTYLES ADDOPTIONS DELOPTIONS ' +
         'ADDLINES DELLINES ADDSECTIONS ADDBORDERICONS DELBORDERICONS ') = 0 then
    Exit;
  ArgsFrom := NextSig(AToks, LastMember + 1, ATo);
  if ArgsFrom < 0 then
    Exit;
  ArgsTo := PrevSig(AToks, ATo);
  OpenIdx := ArgsFrom;
  if IsOp(AToks, OpenIdx, '(') then
  begin
    CloseIdx := MatchParen(AToks, OpenIdx, ATo);
    if (CloseIdx > 0) and (CloseIdx = ArgsTo) then
    begin
      ArgsFrom := OpenIdx + 1;
      ArgsTo := CloseIdx - 1;
    end;
  end;
  Args := TStringList.Create;
  try
    Depth := 0;
    ArgStart := ArgsFrom;
    for TokIdx := ArgsFrom to ArgsTo do
    begin
      if IsOp(AToks, TokIdx, '(') then
        Inc(Depth)
      else if IsOp(AToks, TokIdx, ')') then
        Dec(Depth)
      else if (Depth = 0) and IsOp(AToks, TokIdx, ',') then
      begin
        Args.Add(RangeText(AToks, ArgStart, TokIdx - 1));
        ArgStart := TokIdx + 1;
      end;
    end;
    Args.Add(RangeText(AToks, ArgStart, ArgsTo));
    if Args.Count <= ChunkSize then
    begin
      FLostLines := 0;
      Exit;
    end;
    ObjText := RangeText(AToks, AFirst, LastMember);
    CallText := '';
    ChunkText := '';
    ArgCount := 0;
    for TokIdx := 0 to Args.Count - 1 do
    begin
      if ChunkText <> '' then
        ChunkText := ChunkText + ', ';
      ChunkText := ChunkText + Args[TokIdx];
      Inc(ArgCount);
      if (ArgCount = ChunkSize) or (TokIdx = Args.Count - 1) then
      begin
        if CallText <> '' then
          CallText := CallText + ' : ';
        CallText := CallText + ObjText + ' ' + ChunkText;
        ChunkText := '';
        ArgCount := 0;
      end;
    end;
    FLostLines := 0;
    Rebuild(AToks, AFirst, ATo, CallText);
  finally
    Args.Free;
  end;
end;

// INC перем [, n] / INC(перем [, n]) -> перем += n; DEC -> -=.
// Перем - и элемент массива, и поле (INC(This.RowNum, h) в rapidq.inc)
procedure TRqFbConv.ProcessIncDec(var AToks: TToks; AFrom, ATo: Integer);
var
  OpenIdx, CloseIdx, ArgFrom, ArgTo, CommaIdx, TargetIdx, TokIdx,
    Depth: Integer;
  Target, Step, OpText: string;
  VarRec: TRqVar;
begin
  ArgFrom := AFrom + 1;
  ArgTo := ATo;
  OpenIdx := NextSig(AToks, AFrom + 1, ATo);
  if IsOp(AToks, OpenIdx, '(') then
  begin
    CloseIdx := MatchParen(AToks, OpenIdx, ATo);
    if (CloseIdx > 0) and (NextSig(AToks, CloseIdx + 1, ATo) < 0) then
    begin
      ArgFrom := OpenIdx + 1;
      ArgTo := CloseIdx - 1;
    end;
  end;
  CommaIdx := ArgTo + 1;
  Depth := 0;
  for TokIdx := ArgFrom to ArgTo do
  begin
    if IsOp(AToks, TokIdx, '(') then
      Inc(Depth)
    else if IsOp(AToks, TokIdx, ')') then
      Dec(Depth)
    else if (Depth = 0) and IsOp(AToks, TokIdx, ',') then
    begin
      CommaIdx := TokIdx;
      Break;
    end;
  end;
  TargetIdx := NextSig(AToks, ArgFrom, CommaIdx - 1);
  if (TargetIdx < 0) or (AToks[TargetIdx].Kind <> tkIdent) then
    Exit;
  ProcessExpr(AToks, TargetIdx, CommaIdx - 1);
  VarRec := FindVar(AToks[TargetIdx].Up);
  if VarRec <> nil then
    VarRec.Assigned := True;
  Target := RangeText(AToks, TargetIdx, CommaIdx - 1);
  Step := '1';
  if CommaIdx < ArgTo then
  begin
    ProcessExpr(AToks, CommaIdx + 1, ArgTo);
    Step := '(' + RangeText(AToks, CommaIdx + 1, ArgTo) + ')';
  end;
  if AToks[AFrom].Up = 'INC' then
    OpText := ' += '
  else
    OpText := ' -= ';
  Rebuild(AToks, AFrom, ATo, Target + OpText + Step);
end;

// ---------------------------------------------------------------------------
//  Свои компоненты: TYPE Имя EXTENDS Класс ... END TYPE (глава 10
//  документации RapidQ)
//
//  Перевод в FreeBASIC:
//    - в строке TYPE - Type Имя Extends Класс со всеми полями и Declare
//      методов (собраны в первом проходе), затем #line;
//    - поле - поле Type; поле с PROPERTY SET Установщик - значение
//      RqVal_Поле и свойство FreeBASIC Поле: снаружи запись вызывает
//      установщик, внутри TYPE This.Поле - само значение (без вызова:
//      иначе установщик, который пишет в поле, вызывал бы себя);
//      Поле AS EVENT(Шаблон) - Any Ptr, CALLFUNC - вызов по типу шаблона;
//    - SUB, FUNCTION, PROPERTY SET - методы (Sub Имя.Метод на месте
//      исходника), CONSTRUCTOR - Constructor (вначале подключаются
//      события), EVENT OnXxx / EVENT Поле.OnXxx - метод InheritOnXxx /
//      RqEv_Поле_OnXxx и переходник: процедура модуля с Sender, которая
//      вызывает метод объекта (объект - Sender или, для поля, по смещению
//      поля OffsetOf);
//    - Имя.x, This.x, .x внутри WITH Имя / WITH This - This.x; Super.x -
//      Base.x; в CONSTRUCTOR член и без имени объекта (Caption = "x");
//    - внутри метода переменная, процедура или функция модуля с именем
//      члена компонента или его класса - с ".." (иначе FreeBASIC берёт
//      член).
// ---------------------------------------------------------------------------

function TRqFbConv.FindTypeInfo(const AUp: string): TRqTypeInfo;
var
  Found: Integer;
begin
  Result := nil;
  if FTypeInfos.Find(AUp, Found) then
    Result := TRqTypeInfo(FTypeInfos.Objects[Found]);
end;

// Имя члена в FreeBASIC: суффикс - частью имени (Err$ -> Err__s); слово,
// которым член называться не может (Delete), - с _v
function TRqFbConv.MemberFbName(const ADisplay: string): string;
begin
  if SuffixOf(ADisplay) <> '' then
    Result := Mangle(ADisplay)
  else if InList(FBadMembers, UpperCase(ADisplay)) then
    Result := ADisplay + '_v'
  else
    Result := ADisplay;
  if Pos('~', Result) > 0 then
    Result := StringReplace(Result, '~', '_T_', [rfReplaceAll]);
end;

// Имя совпадает с членом текущего компонента или его класса RapidQ
function TRqFbConv.TypeMemberCollides(const AUp: string): Boolean;
var
  NameUp: string;
begin
  Result := False;
  if FCurType = nil then
    Exit;
  NameUp := BaseOf(AUp);
  Result := (FCurType.Kind(AUp) <> #0) or (FCurType.Kind(NameUp) <> #0) or
            (MemberKind(FCurType.BaseClass, NameUp) <> #0);
end;

// Внутри метода компонента имя модуля, совпадающее с членом, - через ".."
// (FreeBASIC внутри метода сначала ищет член; проверено, fbc 1.10.1)
procedure TRqFbConv.GlobalQualify(var AToks: TToks; AIdx: Integer);
begin
  if (FCurType <> nil) and (FTypeBody <> 0) and
     TypeMemberCollides(AToks[AIdx].Up) and (Pos('..', AToks[AIdx].Pre) = 0) then
    AToks[AIdx].Pre := AToks[AIdx].Pre + '..';
end;

// Параметр или локальная переменная метода с именем члена компонента:
// у FreeBASIC это "Duplicated definition" (для свойств и методов) - с _p
procedure TRqFbConv.FixMemberClash(AVar: TRqVar; const AScope: string);
begin
  if (FCurType = nil) or (Pos('.', AScope) = 0) then
    Exit;
  if FCurType.Kind(AVar.Name) = #0 then
    Exit;
  if Copy(AVar.FbName, Length(AVar.FbName) - 1, 2) <> '_p' then
    AVar.FbName := AVar.FbName + '_p';
end;

// Типы параметров события класса (RqEventSigText); у OnChange и событий
// пунктов параметры только у QTREEVIEW
function TRqFbConv.EventSigFor(const AClassUp, AEventUp: string): string;
begin
  if (AClassUp = 'QLISTVIEW') and (AEventUp = 'ONCHANGE') then
  begin
    Result := FEventSigs.Values['LVONCHANGE'];
    Exit;
  end;
  Result := FEventSigs.Values[AEventUp];
  if (AClassUp <> 'QTREEVIEW') and
     ((AEventUp = 'ONCHANGE') or (AEventUp = 'ONEXPAND') or
      (AEventUp = 'ONCOLLAPSE') or (AEventUp = 'ONCHANGING') or
      (AEventUp = 'ONEXPANDING') or (AEventUp = 'ONCOLLAPSING')) then
    Result := '';
end;

// Имя события для типов параметров обработчика (Объект.OnXxx = Процедура):
// OnChange у QLISTVIEW - LVONCHANGE, иначе имя события
function TRqFbConv.HandlerEventKey(const AToks: TToks; AFirst,
                                   AEventIdx: Integer): string;
var
  VarRec: TRqVar;
begin
  Result := AToks[AEventIdx].Up;
  if (Result = 'ONCHANGE') and (AToks[AFirst].Kind = tkIdent) then
  begin
    VarRec := FindVar(AToks[AFirst].Up);
    if (VarRec <> nil) and (UpperCase(VarRec.RqType) = 'QLISTVIEW') then
      Result := 'LVONCHANGE';
  end;
end;

// Параметры FreeBASIC по типам события ("VLONG;RLONG"). Имена - из ANames
// (по порядку), остальные - RqArgN. AScope <> '' - параметры объявляются
// переменными этой области.
function TRqFbConv.SigParams(const ASig: string; ANames: TStrings;
                             const AScope: string; out ACount: Integer): string;
var
  Rest, Item, ParamName, RqType: string;
  SepPos: Integer;
  VarRec: TRqVar;
begin
  Result := '';
  ACount := 0;
  Rest := ASig;
  if Rest <> '' then
    Rest := Rest + ';';
  while Rest <> '' do
  begin
    SepPos := Pos(';', Rest);
    Item := Copy(Rest, 1, SepPos - 1);
    System.Delete(Rest, 1, SepPos);
    if Length(Item) < 2 then
      Continue;
    RqType := Copy(Item, 2, MaxInt);
    if (ANames <> nil) and (ACount < ANames.Count) then
      ParamName := ANames[ACount]
    else
      ParamName := 'RqArg' + IntToStr(ACount + 1);
    if AScope <> '' then
    begin
      VarRec := DeclareVar(ParamName, RqType, AScope, False, True, False);
      VarRec.RqType := RqType;
      FixMemberClash(VarRec, AScope);
      ParamName := VarRec.FbName;
    end;
    if Result <> '' then
      Result := Result + ', ';
    if Item[1] = 'R' then
      Result := Result + 'ByRef '
    else
      Result := Result + 'ByVal ';
    Result := Result + ParamName + ' As ' + FbType(RqType);
    Inc(ACount);
  end;
end;

// Необъявленные переменные процедуры (области AScope), которых нет в
// модуле, - локальные: " : Dim ..." в строке заголовка
function TRqFbConv.LocalsText(const AScope: string): string;
var
  VarIdx: Integer;
  VarRec: TRqVar;
begin
  Result := '';
  if FPass <> 2 then
    Exit;
  for VarIdx := 0 to FVars.Count - 1 do
  begin
    VarRec := TRqVar(FVars.Objects[VarIdx]);
    if (VarRec.Scope = AScope) and not VarRec.Explicit then
      Result := Result + ' : Dim ' + VarRec.FbName + ' As ' +
                FbType(VarRec.RqType);
  end;
  // GOSUB/RETURN в методе - свой стек возврата, как в SUB
  if FGosubSites.IndexOfName(AScope) >= 0 then
    Result := Result + ' : Dim rqgs_sp As Long : ReDim rqgs_stk(1 To 16) As Long';
end;

// Строка внутри TYPE ... EXTENDS до разбора: Имя.x и This.x -> This.x;
// .x внутри WITH Имя / WITH This -> This.x; в CONSTRUCTOR член
// компонента без имени объекта (и член класса RapidQ в начале оператора)
// -> This.x. WITH Имя, WITH This, END WITH к ним, PUBLIC:, PRIVATE:,
// PROTECTED: убираются. Заодно отслеживается, внутри чего строка
// (FTypeBody): заголовки и концы SUB, FUNCTION, EVENT, CONSTRUCTOR...
function TRqFbConv.RewriteTypeText(const AText: string): string;
var
  Toks: TToks;
  TokIdx, StartIdx, LastIdx, Depth, FirstIdx: Integer;
  Changed: Boolean;

  procedure Blank(AFrom, ATo: Integer);
  var
    ClearIdx: Integer;
  begin
    for ClearIdx := AFrom to ATo do
      if Toks[ClearIdx].Kind <> tkSpace then
        Toks[ClearIdx].Text := '';
    Changed := True;
  end;

  function IsLocalName(const AUp: string): Boolean;
  var
    VarRec: TRqVar;
  begin
    VarRec := FindVar(AUp);
    Result := (VarRec <> nil) and (VarRec.Scope <> '') and VarRec.Explicit;
  end;

  // "." перед членом объекта WITH: в начале выражения (после знака, кроме
  // ")", или ключевого слова вроде THEN)
  function IsWithDot(ADotIdx, ATo: Integer): Boolean;
  var
    PrevIdx, AfterIdx: Integer;
  begin
    Result := False;
    AfterIdx := NextSig(Toks, ADotIdx + 1, ATo);
    if (AfterIdx < 0) or (Toks[AfterIdx].Kind <> tkIdent) then
      Exit;
    PrevIdx := PrevSig(Toks, ADotIdx - 1);
    if PrevIdx < 0 then
      Result := True
    else if Toks[PrevIdx].Kind = tkOp then
      Result := (Toks[PrevIdx].Text <> ')') and (Toks[PrevIdx].Text <> '.')
    else if Toks[PrevIdx].Kind = tkIdent then
      Result := InList(FKeywords, Toks[PrevIdx].Up) and
                (Toks[PrevIdx].Up <> 'THIS') and (Toks[PrevIdx].Up <> 'SUPER') and
                (Toks[PrevIdx].Text <> 'This');
  end;

  procedure DoStatement(AFrom, ATo: Integer);
  var
    Up, WithTop: string;
    NextIdx, PrevIdx, AfterIdx, RefIdx: Integer;
    Kind: Char;
    StmtStart: Boolean;
  begin
    FirstIdx := NextSig(Toks, AFrom, ATo);
    if FirstIdx < 0 then
      Exit;
    NextIdx := NextSig(Toks, FirstIdx + 1, ATo);
    if Toks[FirstIdx].Kind = tkIdent then
    begin
      Up := Toks[FirstIdx].Up;
      if (Up = 'SUB') or (Up = 'FUNCTION') or (Up = 'SUBI') or
         (Up = 'FUNCTIONI') then
      begin
        FTypeBody := 1;
        Exit;
      end;
      if (Up = 'PROPERTY') and IsWord(Toks, NextIdx, 'SET') then
      begin
        FTypeBody := 4;
        Exit;
      end;
      if Up = 'EVENT' then
      begin
        FTypeBody := 3;
        Exit;
      end;
      if Up = 'CONSTRUCTOR' then
      begin
        FTypeBody := 2;
        Exit;
      end;
      if Up = 'END' then
      begin
        if IsWord(Toks, NextIdx, 'SUB') or IsWord(Toks, NextIdx, 'FUNCTION') or
           IsWord(Toks, NextIdx, 'SUBI') or IsWord(Toks, NextIdx, 'FUNCTIONI') or
           IsWord(Toks, NextIdx, 'PROPERTY') or IsWord(Toks, NextIdx, 'EVENT') or
           IsWord(Toks, NextIdx, 'CONSTRUCTOR') then
          FTypeBody := 0
        else if IsWord(Toks, NextIdx, 'WITH') then
        begin
          WithTop := Copy(FTypeWith, Length(FTypeWith), 1);
          if FTypeWith <> '' then
            System.Delete(FTypeWith, Length(FTypeWith), 1);
          if WithTop = 'T' then
            Blank(AFrom, ATo);
        end;
        Exit;
      end;
      if Up = 'WITH' then
      begin
        if (IsWord(Toks, NextIdx, FCurType.Name) or IsWord(Toks, NextIdx, 'THIS')) and
           (NextSig(Toks, NextIdx + 1, ATo) < 0) then
        begin
          FTypeWith := FTypeWith + 'T';
          Blank(AFrom, ATo);
          Exit;
        end;
        FTypeWith := FTypeWith + 'O';
      end;
      if ((Up = 'PUBLIC') or (Up = 'PRIVATE') or (Up = 'PROTECTED')) and
         (NextIdx < 0) then
      begin
        Blank(AFrom, ATo);
        if IsOp(Toks, ATo + 1, ':') then
          Toks[ATo + 1].Text := '';
        Exit;
      end;
    end;
    if FTypeBody = 0 then
      Exit;
    for RefIdx := AFrom to ATo do
    begin
      if Toks[RefIdx].Kind = tkIdent then
      begin
        PrevIdx := PrevSig(Toks, RefIdx - 1);
        // после "." (и после ".", уже ставшей "This.")
        if (PrevIdx >= 0) and (Toks[PrevIdx].Kind = tkOp) and
           ((Toks[PrevIdx].Text = '.') or (Toks[PrevIdx].Text = 'This.')) then
          Continue;
        AfterIdx := NextSig(Toks, RefIdx + 1, ATo);
        Up := Toks[RefIdx].Up;
        if ((Up = FCurType.Name) or (Up = 'THIS')) and IsOp(Toks, AfterIdx, '.') then
        begin
          Toks[RefIdx].Text := 'This';
          Changed := True;
          Continue;
        end;
        if FTypeBody <> 2 then
          Continue;
        // CONSTRUCTOR: член без имени объекта
        if IsLocalName(Up) or InList(FTypes, Up) then
          Continue;
        StmtStart := (RefIdx = FirstIdx) or IsWord(Toks, PrevIdx, 'THEN') or
                     IsWord(Toks, PrevIdx, 'ELSE');
        Kind := FCurType.Kind(Up);
        if (Kind = #0) and StmtStart and not IsOp(Toks, AfterIdx, '#') and
           (MemberKind(FCurType.BaseClass, Up) <> #0) then
          Kind := 'B';
        if Kind <> #0 then
        begin
          Toks[RefIdx].Text := 'This.' + Toks[RefIdx].Text;
          Changed := True;
        end;
      end
      else if IsOp(Toks, RefIdx, '.') and
              (Copy(FTypeWith, Length(FTypeWith), 1) = 'T') and
              IsWithDot(RefIdx, ATo) then
      begin
        Toks[RefIdx].Text := 'This.';
        Changed := True;
      end;
    end;
  end;

begin
  Result := AText;
  Lex(AText, Toks);
  Changed := False;
  LastIdx := High(Toks);
  for TokIdx := 0 to High(Toks) do
    if Toks[TokIdx].Kind = tkComment then
    begin
      LastIdx := TokIdx - 1;
      Break;
    end;
  FirstIdx := NextSig(Toks, 0, LastIdx);
  if (FirstIdx < 0) or (Toks[FirstIdx].Kind = tkDirective) then
    Exit;
  Depth := 0;
  StartIdx := 0;
  TokIdx := 0;
  while TokIdx <= LastIdx do
  begin
    if IsOp(Toks, TokIdx, '(') then
      Inc(Depth)
    else if IsOp(Toks, TokIdx, ')') then
      Dec(Depth)
    else if (Depth = 0) and IsOp(Toks, TokIdx, ':') then
    begin
      if TokIdx - 1 >= StartIdx then
        DoStatement(StartIdx, TokIdx - 1);
      StartIdx := TokIdx + 1;
    end;
    Inc(TokIdx);
  end;
  if StartIdx <= LastIdx then
    DoStatement(StartIdx, LastIdx);
  if not Changed then
    Exit;
  Result := '';
  for TokIdx := 0 to High(Toks) do
    Result := Result + Toks[TokIdx].Text;
end;

// Оператор внутри TYPE ... EXTENDS. True - обработан здесь (заголовок или
// конец метода, поле, END TYPE); False - обычный оператор тела метода
function TRqFbConv.TypeStatement(var AToks: TToks; AFirst, ATo: Integer): Boolean;
var
  Up: string;
  NextIdx: Integer;
begin
  Result := FTypeBody = 0;
  if AToks[AFirst].Kind <> tkIdent then
  begin
    if Result then
    begin
      Warn('внутри TYPE ' + FCurType.Display + ' непонятный оператор: ' +
           RawText(AToks, AFirst, ATo));
      Rebuild(AToks, AFirst, ATo, '');
    end;
    Exit;
  end;
  Result := True;
  Up := AToks[AFirst].Up;
  NextIdx := NextSig(AToks, AFirst + 1, ATo);
  if Up = 'END' then
  begin
    if IsWord(AToks, NextIdx, 'TYPE') then
      TypeEnd(AToks, AFirst, ATo)
    else if IsWord(AToks, NextIdx, 'CONSTRUCTOR') then
      Rebuild(AToks, AFirst, ATo, 'End Constructor')
    else if IsWord(AToks, NextIdx, 'FUNCTION') or IsWord(AToks, NextIdx, 'FUNCTIONI') then
      Rebuild(AToks, AFirst, ATo, 'End Function')
    else if IsWord(AToks, NextIdx, 'SUB') or IsWord(AToks, NextIdx, 'SUBI') or
            IsWord(AToks, NextIdx, 'PROPERTY') or IsWord(AToks, NextIdx, 'EVENT') then
      Rebuild(AToks, AFirst, ATo, 'End Sub')
    else
    begin
      Result := False;
      Exit;
    end;
    FCurProc := nil;
    FCurMethodUp := '';
    Exit;
  end;
  if (Up = 'SUB') or (Up = 'FUNCTION') or (Up = 'SUBI') or (Up = 'FUNCTIONI') then
  begin
    TypeMethodHeader(AToks, AFirst, ATo, False);
    Exit;
  end;
  if (Up = 'PROPERTY') and IsWord(AToks, NextIdx, 'SET') then
  begin
    TypeMethodHeader(AToks, AFirst, ATo, True);
    Exit;
  end;
  if Up = 'EVENT' then
  begin
    TypeEventHeader(AToks, AFirst, ATo);
    Exit;
  end;
  if Up = 'CONSTRUCTOR' then
  begin
    TypeCtorHeader(AToks, AFirst, ATo);
    Exit;
  end;
  if FTypeBody <> 0 then
  begin
    if Up = 'CALLFUNC' then
      TypeCallFunc(AToks, AFirst, ATo)
    else
      Result := False;
    Exit;
  end;
  // Уровень TYPE: DECLARE, CONST - как обычно (в FreeBASIC - на уровне
  // модуля, между методами); остальное - поля
  if (Up = 'DECLARE') or (Up = 'CONST') or
     (((Up = 'PUBLIC') or (Up = 'PRIVATE')) and IsWord(AToks, NextIdx, 'CONST')) then
  begin
    Result := False;
    Exit;
  end;
  if Up = 'DIM' then
  begin
    if NextIdx < 0 then
      Exit;
    AToks[AFirst].OutText := '';
    TypeField(AToks, NextIdx, ATo);
    Exit;
  end;
  TypeField(AToks, AFirst, ATo);
end;

// SUB/FUNCTION Имя[(параметры)] [AS тип] и PROPERTY SET Имя(параметр)
// внутри TYPE -> Sub/Function Компонент.Имя(...)
procedure TRqFbConv.TypeMethodHeader(var AToks: TToks; AFirst, ATo: Integer;
                                     AIsSetter: Boolean);
var
  NameIdx, OpenIdx, CloseIdx, AsIdx, TypeIdx, ParamCount, SpacePos: Integer;
  KindUp, Display, NameUp, FbName, Params, RetType, StarLen, DeclText: string;
  IsFunc: Boolean;
  ProcRec: TRqProc;
  Kind: Char;
begin
  KindUp := AToks[AFirst].Up;
  if AIsSetter then
    NameIdx := NextSig(AToks, NextSig(AToks, AFirst + 1, ATo) + 1, ATo)
  else
    NameIdx := NextSig(AToks, AFirst + 1, ATo);
  if (NameIdx < 0) or (AToks[NameIdx].Kind <> tkIdent) then
  begin
    Error(AToks[AFirst].Text + ': ожидалось имя');
    Exit;
  end;
  IsFunc := (KindUp = 'FUNCTION') or (KindUp = 'FUNCTIONI');
  Display := AToks[NameIdx].Text;
  NameUp := AToks[NameIdx].Up;
  FbName := MemberFbName(Display);
  ProcRec := GetProc(FCurType.Name + '.' + NameUp);
  ProcRec.IsFunc := IsFunc;
  ProcRec.IsVariadic := (KindUp = 'SUBI') or (KindUp = 'FUNCTIONI');
  FCurProc := ProcRec;
  FCurMethodUp := NameUp;
  FGosubProcNum := 0;
  OpenIdx := NextSig(AToks, NameIdx + 1, ATo);
  Params := '';
  CloseIdx := NameIdx;
  if IsOp(AToks, OpenIdx, '(') then
  begin
    CloseIdx := MatchParen(AToks, OpenIdx, ATo);
    if CloseIdx < 0 then
      CloseIdx := ATo;
    if not ProcRec.IsVariadic then
      Params := ParseParams(AToks, OpenIdx + 1, CloseIdx - 1, ProcRec.Name);
  end;
  if ProcRec.IsVariadic then
    Params := VariadicParam;
  RetType := SuffixType(SuffixOf(NameUp));
  AsIdx := NextSig(AToks, CloseIdx + 1, ATo);
  if IsWord(AToks, AsIdx, 'AS') then
  begin
    TypeIdx := NextSig(AToks, AsIdx + 1, ATo);
    if TypeIdx >= 0 then
      RetType := ParseType(AToks, TypeIdx, ATo, StarLen);
  end;
  ProcRec.RetType := RetType;
  if IsFunc then
    DeclText := 'Function ' + FbName + '(' + Params + ') As ' + FbType(RetType)
  else
    DeclText := 'Sub ' + FbName + '(' + Params + ')';
  if FPass = 1 then
  begin
    if FCurType.Kind(NameUp) = #0 then
    begin
      if AIsSetter then
        Kind := 'S'
      else if IsFunc then
        Kind := 'N'
      else
        Kind := 'M';
      ParamCount := 0;
      if Params <> '' then
        ParamCount := 1 + (Length(Params) -
                           Length(StringReplace(Params, ', ', ',', [rfReplaceAll])));
      FCurType.Members.Add(NameUp + '=' + Kind);
      FCurType.MemberFb.Add(NameUp + '=' + FbName);
      FCurType.MemberType.Add(NameUp + '=' + RetType);
      FCurType.ParamCounts.Add(NameUp + '=' + IntToStr(ParamCount));
      FCurType.Decls.Add('Declare ' + DeclText);
      if ProcRec.IsVariadic then
      begin
        FCurType.Variadic.Add(NameUp);
        FCurType.ParamCounts.Values[NameUp] := '-1';
      end;
      // Объект.Delete, Объект.Err$ снаружи - тем же именем
      if FbName <> Display then
        FMemberMap.Values[NameUp] := FbName;
    end;
  end;
  SpacePos := Pos(' ', DeclText);
  Rebuild(AToks, AFirst, ATo, Copy(DeclText, 1, SpacePos) + FCurType.Display + '.' +
          Copy(DeclText, SpacePos + 1, MaxInt) + LocalsText(ProcRec.Name));
end;

// EVENT OnXxx [(параметры)] / EVENT Поле.OnXxx [(параметры)] - обработчик
// события самого компонента или его поля: метод InheritOnXxx /
// RqEv_Поле_OnXxx (типы параметров - по событию; имена - из заголовка,
// их может быть меньше) и переходник с Sender, который подключается в
// конструкторе
procedure TRqFbConv.TypeEventHeader(var AToks: TToks; AFirst, ATo: Integer);
var
  NameIdx, DotIdx, EventIdx, OpenIdx, CloseIdx, TokIdx, Depth,
    ParamCount: Integer;
  CompUp, CompFb, ClassUp, EventUp, EventDisplay, MethName, MethUp, Params,
    ThunkName: string;
  Names: TStringList;
  ExpectName: Boolean;
  ProcRec: TRqProc;
begin
  NameIdx := NextSig(AToks, AFirst + 1, ATo);
  if (NameIdx < 0) or (AToks[NameIdx].Kind <> tkIdent) then
  begin
    Error('EVENT: ожидалось имя события');
    Exit;
  end;
  DotIdx := NextSig(AToks, NameIdx + 1, ATo);
  CompUp := '';
  CompFb := '';
  if IsOp(AToks, DotIdx, '.') then
  begin
    EventIdx := NextSig(AToks, DotIdx + 1, ATo);
    if (EventIdx < 0) or (AToks[EventIdx].Kind <> tkIdent) then
    begin
      Error('EVENT: ожидалось Поле.Событие');
      Exit;
    end;
    CompUp := AToks[NameIdx].Up;
    CompFb := MemberFbName(AToks[NameIdx].Text);
    ClassUp := FCurType.MemberType.Values[CompUp];
    if FCurType.Kind(CompUp) <> 'F' then
      Warn('EVENT ' + RawText(AToks, NameIdx, EventIdx) + ': поля ' +
           AToks[NameIdx].Text + ' нет в TYPE ' + FCurType.Display);
  end
  else
  begin
    EventIdx := NameIdx;
    ClassUp := FCurType.BaseClass;
  end;
  EventUp := AToks[EventIdx].Up;
  EventDisplay := AToks[EventIdx].Text;
  if CompUp = '' then
    MethName := 'Inherit' + EventDisplay
  else
    MethName := 'RqEv_' + CompFb + '_' + EventDisplay;
  MethUp := UpperCase(MethName);
  ProcRec := GetProc(FCurType.Name + '.' + MethUp);
  ProcRec.IsFunc := False;
  FCurProc := ProcRec;
  FCurMethodUp := MethUp;
  FGosubProcNum := 0;
  Names := TStringList.Create;
  try
    OpenIdx := NextSig(AToks, EventIdx + 1, ATo);
    if IsOp(AToks, OpenIdx, '(') then
    begin
      CloseIdx := MatchParen(AToks, OpenIdx, ATo);
      if CloseIdx < 0 then
        CloseIdx := ATo + 1;
      Depth := 0;
      ExpectName := True;
      for TokIdx := OpenIdx + 1 to CloseIdx - 1 do
      begin
        if IsOp(AToks, TokIdx, '(') then
          Inc(Depth)
        else if IsOp(AToks, TokIdx, ')') then
          Dec(Depth)
        else if (Depth = 0) and IsOp(AToks, TokIdx, ',') then
          ExpectName := True
        else if ExpectName and (AToks[TokIdx].Kind = tkIdent) and
                not IsWord(AToks, TokIdx, 'BYVAL') and
                not IsWord(AToks, TokIdx, 'BYREF') then
        begin
          Names.Add(AToks[TokIdx].Text);
          ExpectName := False;
        end;
      end;
    end;
    Params := SigParams(EventSigFor(ClassUp, EventUp), Names, ProcRec.Name,
                        ParamCount);
    if Names.Count > ParamCount then
      Warn('EVENT ' + EventDisplay + ': параметров ' + IntToStr(Names.Count) +
           ', у события ' + IntToStr(ParamCount) + ' - лишние пропущены');
  finally
    Names.Free;
  end;
  if (FPass = 1) and (FCurType.Kind(MethUp) = #0) then
  begin
    FCurType.Members.Add(MethUp + '=M');
    FCurType.MemberFb.Add(MethUp + '=' + MethName);
    FCurType.ParamCounts.Add(MethUp + '=' + IntToStr(ParamCount));
    FCurType.Decls.Add('Declare Sub ' + MethName + '(' + Params + ')');
    if CompFb <> '' then
    begin
      ThunkName := FCurType.Display + '__RqEv_' + CompFb + '_' + EventDisplay;
      FCurType.Regs := FCurType.Regs + ' : This.' + CompFb + '.' + EventDisplay +
                       ' = @' + ThunkName;
    end
    else
    begin
      ThunkName := FCurType.Display + '__RqEv_' + EventDisplay;
      FCurType.Regs := FCurType.Regs + ' : This.' + EventDisplay + ' = @' +
                       ThunkName;
    end;
    AddThunk(ThunkName, CompFb, ClassUp, EventDisplay, MethUp);
  end;
  Rebuild(AToks, AFirst, ATo, 'Sub ' + FCurType.Display + '.' + MethName + '(' +
          Params + ')' + LocalsText(ProcRec.Name));
end;

// CONSTRUCTOR -> Constructor Компонент() : подключение событий
procedure TRqFbConv.TypeCtorHeader(var AToks: TToks; AFirst, ATo: Integer);
var
  ProcRec: TRqProc;
begin
  ProcRec := GetProc(FCurType.Name + '.$CTOR');
  ProcRec.IsFunc := False;
  FCurProc := ProcRec;
  FCurMethodUp := '';
  FGosubProcNum := 0;
  if FPass = 1 then
    FCurType.HasCtor := True;
  Rebuild(AToks, AFirst, ATo, 'Constructor ' + FCurType.Display + '()' +
          FCurType.Regs + LocalsText(ProcRec.Name));
end;

// Поле: Имя[(размеры)] AS тип [PROPERTY SET Установщик] или
// Имя AS EVENT(Шаблон). В выводе строка пустая - поле в Type (строка TYPE).
procedure TRqFbConv.TypeField(var AToks: TToks; AFirst, ATo: Integer);
var
  NameIdx, OpenIdx, CloseIdx, AsIdx, TypeIdx, PropIdx, SetterIdx, TplIdx,
    TplClose: Integer;
  Display, NameUp, FbName, DimsText, RqType, StarLen, FbTypeText, ByText,
    TplUp, TplFb: string;
  Kind: Char;
  TplProc: TRqProc;
begin
  NameIdx := AFirst;
  if AToks[NameIdx].Kind <> tkIdent then
  begin
    Warn('внутри TYPE ' + FCurType.Display + ' непонятный оператор: ' +
         RawText(AToks, AFirst, ATo));
    Rebuild(AToks, AFirst, ATo, '');
    Exit;
  end;
  Display := AToks[NameIdx].Text;
  NameUp := AToks[NameIdx].Up;
  FbName := MemberFbName(Display);
  OpenIdx := NextSig(AToks, NameIdx + 1, ATo);
  DimsText := '';
  CloseIdx := NameIdx;
  if IsOp(AToks, OpenIdx, '(') then
  begin
    CloseIdx := MatchParen(AToks, OpenIdx, ATo);
    if CloseIdx < 0 then
      CloseIdx := ATo;
    ProcessExpr(AToks, OpenIdx + 1, CloseIdx - 1);
    DimsText := RangeText(AToks, OpenIdx, CloseIdx);
  end;
  Kind := 'F';
  RqType := SuffixType(SuffixOf(NameUp));
  StarLen := '';
  TplUp := '';
  TplFb := '';
  TypeIdx := CloseIdx;
  AsIdx := NextSig(AToks, CloseIdx + 1, ATo);
  if IsWord(AToks, AsIdx, 'AS') then
  begin
    TypeIdx := NextSig(AToks, AsIdx + 1, ATo);
    if IsWord(AToks, TypeIdx, 'EVENT') then
    begin
      // Событие компонента: указатель на процедуру; тип - по шаблону
      // (DECLARE SUB Шаблон ...), для CALLFUNC
      Kind := 'E';
      TplIdx := NextSig(AToks, TypeIdx + 1, ATo);
      if IsOp(AToks, TplIdx, '(') then
      begin
        TplClose := MatchParen(AToks, TplIdx, ATo);
        TplIdx := NextSig(AToks, TplIdx + 1, ATo);
        if (TplIdx >= 0) and (AToks[TplIdx].Kind = tkIdent) and
           ((TplClose < 0) or (TplIdx < TplClose)) then
          TplUp := AToks[TplIdx].Up;
      end;
      RqType := TplUp;
    end
    else if TypeIdx >= 0 then
      RqType := ParseType(AToks, TypeIdx, ATo, StarLen);
  end;
  PropIdx := NextSig(AToks, TypeIdx + 1, ATo);
  SetterIdx := -1;
  if (Kind = 'F') and IsWord(AToks, PropIdx, 'PROPERTY') and
     IsWord(AToks, NextSig(AToks, PropIdx + 1, ATo), 'SET') then
  begin
    SetterIdx := NextSig(AToks, NextSig(AToks, PropIdx + 1, ATo) + 1, ATo);
    if (SetterIdx < 0) or (AToks[SetterIdx].Kind <> tkIdent) then
      SetterIdx := -1
    else if IsObjectType(RqType) or (DimsText <> '') then
    begin
      Warn(Display + ' PROPERTY SET: у поля-объекта или массива не ' +
           'поддержано - обычное поле');
      SetterIdx := -1;
    end
    else
      Kind := 'P';
  end;
  if (FPass = 1) and (FCurType.Kind(NameUp) = #0) then
  begin
    FbTypeText := FbType(RqType);
    if StarLen <> '' then
      FbTypeText := FbTypeText + ' * ' + StarLen;
    FCurType.Members.Add(NameUp + '=' + Kind);
    FCurType.MemberFb.Add(NameUp + '=' + FbName);
    FCurType.MemberType.Add(NameUp + '=' + RqType);
    if FbName <> Display then
      FMemberMap.Values[NameUp] := FbName;
    case Kind of
      'E':
        begin
          FCurType.Decls.Add(FbName + ' As Any Ptr');
          TplProc := FindProc(TplUp);
          if TplProc <> nil then
          begin
            TplFb := 'RqTpl_' + TplProc.FbName;
            if FCurType.Before.IndexOf('Type ' + TplFb) < 0 then
            begin
              if TplProc.IsFunc then
                FCurType.Before.Add('Type ' + TplFb + ' As Function(' +
                  TplProc.DeclParams + ') As ' + FbType(TplProc.RetType))
              else
                FCurType.Before.Add('Type ' + TplFb + ' As Sub(' +
                  TplProc.DeclParams + ')');
            end;
          end;
        end;
      'P':
        begin
          if RqType = 'STRING' then
            ByText := 'ByRef'
          else
            ByText := 'ByVal';
          FCurType.Decls.Add('RqVal_' + FbName + ' As ' + FbTypeText);
          FCurType.Decls.Add('Declare Property ' + FbName + '() As ' + FbTypeText);
          FCurType.Decls.Add('Declare Property ' + FbName + '(' + ByText +
                             ' RqValue As ' + FbTypeText + ')');
          FCurType.After.Add('Property ' + FCurType.Display + '.' + FbName +
            '() As ' + FbTypeText + ' : Return This.RqVal_' + FbName +
            ' : End Property');
          FCurType.After.Add('Property ' + FCurType.Display + '.' + FbName + '(' +
            ByText + ' RqValue As ' + FbTypeText + ') : This.' +
            MemberFbName(AToks[SetterIdx].Text) + '(RqValue) : End Property');
        end;
    else
      FCurType.Decls.Add(FbName + DimsText + ' As ' + FbTypeText);
    end;
  end;
  Rebuild(AToks, AFirst, ATo, '');
end;

// Переходник события: процедура модуля, которую вызывает событие (с
// Sender), - вызывает метод своего компонента. Строится в END TYPE
// первого прохода (метод может быть объявлен ниже присваивания).
procedure TRqFbConv.AddThunk(const AName, ACompFb, AClassUp, AEventDisplay,
                             AMethUp: string);
begin
  if FCurType.Thunks.IndexOfName(AName) >= 0 then
    Exit;
  FCurType.Thunks.Add(AName + '=' + ACompFb + '|' + AClassUp + '|' +
                      AEventDisplay + '|' + AMethUp);
end;

// END TYPE: переходники событий (и конструктор, если его нет, а события
// подключать надо), затем #line
procedure TRqFbConv.TypeEnd(var AToks: TToks; AFirst, ATo: Integer);
var
  ThunkIdx, ArgIdx, ArgCount, LineIdx, SepPos: Integer;
  Rest, ThunkName, CompFb, ClassUp, EventDisplay, MethUp, MethFb, Params,
    Args, SelfText, Block: string;
begin
  if FPass = 1 then
  begin
    for ThunkIdx := 0 to FCurType.Thunks.Count - 1 do
    begin
      ThunkName := FCurType.Thunks.Names[ThunkIdx];
      Rest := FCurType.Thunks.ValueFromIndex[ThunkIdx] + '|';
      SepPos := Pos('|', Rest);
      CompFb := Copy(Rest, 1, SepPos - 1);
      System.Delete(Rest, 1, SepPos);
      SepPos := Pos('|', Rest);
      ClassUp := Copy(Rest, 1, SepPos - 1);
      System.Delete(Rest, 1, SepPos);
      SepPos := Pos('|', Rest);
      EventDisplay := Copy(Rest, 1, SepPos - 1);
      System.Delete(Rest, 1, SepPos);
      SepPos := Pos('|', Rest);
      MethUp := Copy(Rest, 1, SepPos - 1);
      Params := SigParams(EventSigFor(ClassUp, UpperCase(EventDisplay)), nil,
                          '', ArgCount);
      if Params <> '' then
        Params := Params + ', ';
      if ClassUp = '' then
        ClassUp := 'QCONTROL';
      Params := Params + 'ByRef Sender As ' + ClassUp;
      Args := '';
      if (ArgCount > 0) and
         (FCurType.ParamCounts.Values[MethUp] = IntToStr(ArgCount)) then
        for ArgIdx := 1 to ArgCount do
        begin
          if Args <> '' then
            Args := Args + ', ';
          Args := Args + 'RqArg' + IntToStr(ArgIdx);
        end;
      MethFb := FCurType.MemberFb.Values[MethUp];
      if MethFb = '' then
        MethFb := MethUp;
      if CompFb = '' then
        SelfText := 'Cast(' + FCurType.Display + ' Ptr, Cast(Any Ptr, @Sender))'
      else
        SelfText := 'Cast(' + FCurType.Display + ' Ptr, Cast(Any Ptr, ' +
          'Cast(UByte Ptr, Cast(Any Ptr, @Sender)) - OffsetOf(' +
          FCurType.Display + ', ' + CompFb + ')))';
      FCurType.After.Add('Declare Sub ' + ThunkName + '(' + Params + ')');
      FCurType.Tail.Add('Sub ' + ThunkName + '(' + Params + ') : ' + SelfText +
                        '->' + MethFb + '(' + Args + ') : End Sub');
    end;
    if not FCurType.HasCtor and (FCurType.Regs <> '') then
      FCurType.Tail.Insert(0, 'Constructor ' + FCurType.Display + '()' +
                           FCurType.Regs + ' : End Constructor');
  end
  else
  begin
    Block := '';
    for LineIdx := 0 to FCurType.Tail.Count - 1 do
      Block := Block + FCurType.Tail[LineIdx] + CrLf;
    if Block <> '' then
      Block := Block + '#line ' + IntToStr(FCurLine + FLineBreaks) + ' "' +
               FCurFile + '"';
    ClearRange(AToks, AFirst, High(AToks));
    FLostLines := 0;
    AToks[AFirst].OutText := Block;
  end;
  FCurType := nil;
  FCurProc := nil;
  FCurMethodUp := '';
  FTypeBody := 0;
  FTypeWith := '';
end;

// Присваивание внутри метода (после RewriteTypeText члены - This.x):
//   This.Установщик = x (PROPERTY SET) -> This.Установщик(x);
//   This.Функция = x в самой FUNCTION -> Function = x;
//   This.OnXxx = This.Метод, This.Поле.OnXxx = This.Метод -> @переходник
function TRqFbConv.TypeAssign(var AToks: TToks; AFirst, AEq, ATo: Integer): Boolean;
var
  SigIdx: array[0..4] of Integer;
  SigCount, TokIdx, RhsFirst, RhsLast, RhsDot, MethIdx: Integer;
  MemberUp, CompUp, CompFb, ClassUp, EventDisplay, MethUp, ThunkName: string;
  Kind: Char;
begin
  Result := False;
  SigCount := 0;
  for TokIdx := AFirst to AEq - 1 do
    if AToks[TokIdx].Kind <> tkSpace then
    begin
      if SigCount > 4 then
        Exit;
      SigIdx[SigCount] := TokIdx;
      Inc(SigCount);
    end;
  if (SigCount <> 3) and (SigCount <> 5) then
    Exit;
  if not IsWord(AToks, SigIdx[0], 'THIS') or not IsOp(AToks, SigIdx[1], '.') or
     (AToks[SigIdx[2]].Kind <> tkIdent) then
    Exit;
  if (SigCount = 5) and (not IsOp(AToks, SigIdx[3], '.') or
                         (AToks[SigIdx[4]].Kind <> tkIdent)) then
    Exit;
  RhsFirst := NextSig(AToks, AEq + 1, ATo);
  RhsLast := PrevSig(AToks, ATo);
  if (RhsFirst < 0) or (RhsLast < RhsFirst) then
    Exit;
  MemberUp := AToks[SigIdx[SigCount - 1]].Up;
  if SigCount = 3 then
  begin
    Kind := FCurType.Kind(MemberUp);
    if Kind = 'S' then
    begin
      ProcessExpr(AToks, AFirst, ATo);
      AToks[AEq].OutText := '(';
      AToks[RhsLast].Post := AToks[RhsLast].Post + ')';
      Result := True;
      Exit;
    end;
    if (MemberUp = FCurMethodUp) and (FCurProc <> nil) and FCurProc.IsFunc then
    begin
      ClearRange(AToks, AFirst, AEq - 1);
      AToks[AFirst].OutText := 'Function ';
      ProcessExpr(AToks, RhsFirst, ATo);
      Result := True;
      Exit;
    end;
  end;
  // OnXxx = This.Метод
  if not IsEventName(MemberUp) then
    Exit;
  RhsDot := NextSig(AToks, RhsFirst + 1, ATo);
  MethIdx := NextSig(AToks, RhsDot + 1, ATo);
  if not IsWord(AToks, RhsFirst, 'THIS') or not IsOp(AToks, RhsDot, '.') or
     (MethIdx <> RhsLast) or (AToks[MethIdx].Kind <> tkIdent) then
    Exit;
  MethUp := AToks[MethIdx].Up;
  if FCurType.Kind(MethUp) in ['F', 'P', 'E'] then
    Exit;
  EventDisplay := AToks[SigIdx[SigCount - 1]].Text;
  if SigCount = 5 then
  begin
    CompUp := AToks[SigIdx[2]].Up;
    if FCurType.Kind(CompUp) <> 'F' then
      Exit;
    CompFb := FCurType.MemberFb.Values[CompUp];
    ClassUp := FCurType.MemberType.Values[CompUp];
    ThunkName := FCurType.Display + '__RqTh_' + CompFb + '_' + EventDisplay + '_' +
                 MemberFbName(AToks[MethIdx].Text);
  end
  else
  begin
    CompFb := '';
    ClassUp := FCurType.BaseClass;
    ThunkName := FCurType.Display + '__RqTh_' + EventDisplay + '_' +
                 MemberFbName(AToks[MethIdx].Text);
  end;
  if FPass = 1 then
    AddThunk(ThunkName, CompFb, ClassUp, EventDisplay, MethUp);
  ProcessExpr(AToks, AFirst, AEq - 1);
  Rebuild(AToks, RhsFirst, RhsLast, '@' + ThunkName);
  Result := True;
end;

// CALLFUNC(This.Событие, параметры) / CALLFUNC This.Событие - вызов
// события компонента (поле AS EVENT(Шаблон)) по типу шаблона
procedure TRqFbConv.TypeCallFunc(var AToks: TToks; AFirst, ATo: Integer);
var
  ArgsFrom, ArgsTo, OpenIdx, CloseIdx, TokIdx, Depth, CommaIdx, DotIdx,
    FieldIdx: Integer;
  FieldUp, TplUp, ArgsText: string;
  TplProc: TRqProc;
begin
  OpenIdx := NextSig(AToks, AFirst + 1, ATo);
  ArgsFrom := OpenIdx;
  ArgsTo := ATo;
  if IsOp(AToks, OpenIdx, '(') then
  begin
    CloseIdx := MatchParen(AToks, OpenIdx, ATo);
    if (CloseIdx > 0) and (NextSig(AToks, CloseIdx + 1, ATo) < 0) then
    begin
      ArgsFrom := OpenIdx + 1;
      ArgsTo := CloseIdx - 1;
    end;
  end;
  // первый параметр - This.Поле
  CommaIdx := ArgsTo + 1;
  Depth := 0;
  for TokIdx := ArgsFrom to ArgsTo do
  begin
    if IsOp(AToks, TokIdx, '(') then
      Inc(Depth)
    else if IsOp(AToks, TokIdx, ')') then
      Dec(Depth)
    else if (Depth = 0) and IsOp(AToks, TokIdx, ',') then
    begin
      CommaIdx := TokIdx;
      Break;
    end;
  end;
  FieldUp := '';
  DotIdx := NextSig(AToks, NextSig(AToks, ArgsFrom, ArgsTo) + 1, ArgsTo);
  FieldIdx := NextSig(AToks, DotIdx + 1, ArgsTo);
  if IsWord(AToks, NextSig(AToks, ArgsFrom, ArgsTo), 'THIS') and
     IsOp(AToks, DotIdx, '.') and (FieldIdx >= 0) and
     (NextSig(AToks, FieldIdx + 1, CommaIdx - 1) < 0) then
    FieldUp := AToks[FieldIdx].Up;
  TplProc := nil;
  if (FieldUp <> '') and (FCurType.Kind(FieldUp) = 'E') then
  begin
    TplUp := FCurType.MemberType.Values[FieldUp];
    TplProc := FindProc(TplUp);
  end;
  if TplProc = nil then
  begin
    Warn('CALLFUNC: поддержан только вызов события компонента ' +
         '(поле AS EVENT(Шаблон) с DECLARE шаблона)');
    ProcessExpr(AToks, AFirst + 1, ATo);
    Exit;
  end;
  ArgsText := '';
  if CommaIdx < ArgsTo then
  begin
    ProcessExpr(AToks, CommaIdx + 1, ArgsTo);
    ArgsText := RangeText(AToks, CommaIdx + 1, ArgsTo);
  end;
  Rebuild(AToks, AFirst, ATo, 'Cast(RqTpl_' + TplProc.FbName + ', This.' +
          FCurType.MemberFb.Values[FieldUp] + ')(' + ArgsText + ')');
end;

// ---------------------------------------------------------------------------
//  Файлы и проходы
// ---------------------------------------------------------------------------

// Заголовок главного файла: режим, рантайм, неявные переменные модуля
function TRqFbConv.MainHeader: string;
var
  VarIdx: Integer;
  VarRec: TRqVar;
begin
  Result := '''' + ' Переведено из RapidQ препроцессором RqToFb (unIDE). ' +
            'Файл создаётся заново при каждой сборке.' + CrLf;
  if FOpt.Mode = rfmCompat then
    Result := Result + '#define RQ_COMPAT' + CrLf
  else
    Result := Result + '#define RQ_SMART' + CrLf;
  if FAppType = 'CONSOLE' then
    Result := Result + '#define RQ_CONSOLE' + CrLf;
  Result := Result + '#include once "rqrt.bi"' + CrLf +
            '#include once "rqstream.bi"' + CrLf +
            '#include once "rqlcl.bi"' + CrLf;
  for VarIdx := 0 to FVars.Count - 1 do
  begin
    VarRec := TRqVar(FVars.Objects[VarIdx]);
    if (VarRec.Scope = '') and not VarRec.Explicit then
      Result := Result + 'Dim Shared ' + VarRec.FbName + ' As ' +
                FbType(VarRec.RqType) + CrLf;
  end;
  if FGosubSites.IndexOfName('*') >= 0 then
    Result := Result + 'Dim Shared rqgs_msp As Long' + CrLf +
              'ReDim Shared rqgs_mstk(1 To 16) As Long' + CrLf;
end;

// После первого прохода: необъявленная в SUB переменная, которая есть в
// модуле, - переменная модуля
procedure TRqFbConv.EndOfPass1;
var
  VarIdx, Found: Integer;
  VarRec: TRqVar;
begin
  for VarIdx := FVars.Count - 1 downto 0 do
  begin
    VarRec := TRqVar(FVars.Objects[VarIdx]);
    if (VarRec.Scope <> '') and not VarRec.Explicit and
       FVars.Find('|' + VarRec.Name, Found) then
    begin
      VarRec.Free;
      FVars.Delete(VarIdx);
    end;
  end;
end;

function TRqFbConv.ProcessFile(const AFileName: string; AIsMain: Boolean): string;
var
  Lines, OutLines: TStringList;
  LineIdx, StartIdx, DoneIdx, Suffix, CreateBase: Integer;
  Text, OutText, OutName, SavedFile: string;
  SavedLine: Integer;
  SavedProc: TRqProc;
begin
  DoneIdx := FDoneFiles.IndexOfName(UpperCase(AFileName));
  if DoneIdx >= 0 then
  begin
    Result := FDoneFiles.ValueFromIndex[DoneIdx];
    Exit;
  end;
  // Имя файла вывода
  OutName := ExtractFileName(AFileName);
  if not AIsMain then
    OutName := ChangeFileExt(OutName, '') + '_' +
               Copy(ExtractFileExt(OutName), 2, MaxInt) + '.bi';
  Suffix := 1;
  while FOutNames.IndexOf(UpperCase(OutName)) >= 0 do
  begin
    Inc(Suffix);
    OutName := ChangeFileExt(OutName, '') + IntToStr(Suffix) + ExtractFileExt(OutName);
  end;
  FOutNames.Add(UpperCase(OutName));
  Result := IncludeTrailingPathDelimiter(FOpt.OutDir) + OutName;
  if CompareText(ExpandFileName(Result), ExpandFileName(AFileName)) = 0 then
  begin
    Error('папка вывода совпадает с папкой исходника: ' + FOpt.OutDir);
    Result := '';
    Exit;
  end;
  FDoneFiles.Add(UpperCase(AFileName) + '=' + Result);

  SavedFile := FCurFile;
  SavedLine := FCurLine;
  SavedProc := FCurProc;
  FCurFile := AFileName;
  FCurProc := nil;
  Lines := TStringList.Create;
  OutLines := TStringList.Create;
  try
    try
      Lines.LoadFromFile(AFileName);
    except
      on E: Exception do
      begin
        Error('не удалось прочитать ' + AFileName + ': ' + E.Message);
        Exit;
      end;
    end;
    LineIdx := 0;
    CreateBase := FCreateStack.Count;
    while LineIdx < Lines.Count do
    begin
      StartIdx := LineIdx;
      Text := Lines[LineIdx];
      while EndsWithContinue(Text) and (LineIdx + 1 < Lines.Count) do
      begin
        Inc(LineIdx);
        Text := Text + CrLf + Lines[LineIdx];
      end;
      FCurFile := AFileName;
      FCurLine := StartIdx + 1;
      FLostLines := 0;
      ProcessLine(Text, OutText);
      OutLines.Add(OutText);
      Inc(LineIdx);
    end;
    // TYPE ... EXTENDS без END TYPE
    if FCurType <> nil then
    begin
      if FPass = 2 then
        Error('TYPE ' + FCurType.Display + ' без END TYPE');
      FCurType := nil;
      FCurProc := nil;
    end;
    // CREATE без END CREATE в этом файле
    if FCreateStack.Count > CreateBase then
    begin
      if FPass = 2 then
        Error('CREATE ' + FCreateStack.Names[FCreateStack.Count - 1] +
              ' без END CREATE');
      while FCreateStack.Count > CreateBase do
        FCreateStack.Delete(FCreateStack.Count - 1);
    end;
    if FPass = 2 then
    begin
      if AIsMain then
        OutLines.Insert(0, MainHeader + '#line 0 "' + AFileName + '"')
      else
        OutLines.Insert(0, '#line 0 "' + AFileName + '"');
      try
        ForceDirectories(FOpt.OutDir);
        OutLines.SaveToFile(Result);
      except
        on E: Exception do
          Error('не удалось записать ' + Result + ': ' + E.Message);
      end;
    end;
  finally
    OutLines.Free;
    Lines.Free;
    FCurFile := SavedFile;
    FCurLine := SavedLine;
    FCurProc := SavedProc;
  end;
end;

function TRqFbConv.Run(const AMainFile: string; var AResult: TRqFbResult): Boolean;
var
  PassIdx: Integer;
begin
  FMainFile := ExpandFileName(AMainFile);
  FOpt.OutDir := ExpandFileName(FOpt.OutDir);
  FSourceMode := '';
  for PassIdx := 1 to 2 do
  begin
    FPass := PassIdx;
    FDoneFiles.Clear;
    FOutNames.Clear;
    FDefines.Clear;
    FResources.Clear;
    SetLength(FConds, 0);
    FCurProc := nil;
    FInType := False;
    FPlainType := '';
    FFixBodies := '';
    FCurType := nil;
    FTypeBody := 0;
    FTypeWith := '';
    FCurMethodUp := '';
    FCreateDepth := 0;
    FTypeCheck := False;
    FEscape := False;
    FDefaultType := 'DOUBLE';
    FByRefDefault := False;
    FGosubProcNum := 0;
    FGosubModNum := 0;
    if PassIdx = 1 then
    begin
      FAppType := '';
      FHasGui := False;
      FGosubSites.Clear;
    end
    else
    begin
      // $APPTYPE не задан - по классам из DIM
      if FAppType = '' then
      begin
        if FHasGui then
          FAppType := 'GUI'
        else
          FAppType := 'CONSOLE';
      end;
    end;
    AResult.MainOut := ProcessFile(FMainFile, True);
    if PassIdx = 1 then
    begin
      EndOfPass1;
      // режим из исходника - сильнее настройки
      if FSourceMode = 'SMART' then
        FOpt.Mode := rfmSmart
      else if FSourceMode = 'COMPAT' then
        FOpt.Mode := rfmCompat;
    end;
  end;
  if Length(FConds) > 0 then
  begin
    FCurFile := FMainFile;
    Error('$IFDEF без $ENDIF');
  end;
  AResult.AppType := FAppType;
  AResult.Mode := FOpt.Mode;
  AResult.ErrorCount := FErrors;
  AResult.WarningCount := FWarnings;
  AResult.ResourceFile := WriteResources;
  Result := FErrors = 0;
end;

procedure TRqFbConv.ProcessResource(var AToks: TToks; AFrom, ATo, AArgIdx: Integer;
                                    const AOriginal: string; var AOut: string);
var
  AsIdx, NameIdx, CloseIdx, ResIdx: Integer;
  ResName, FileName, Found: string;
  Angle: Boolean;
  VarRec: TRqVar;
begin
  NameIdx := AArgIdx;
  if (NameIdx < 0) or (AToks[NameIdx].Kind <> tkIdent) then
  begin
    Error('$RESOURCE: нужно имя (Имя AS "файл")');
    Exit;
  end;
  AsIdx := NextSig(AToks, NameIdx + 1, ATo);
  if not IsWord(AToks, AsIdx, 'AS') then
  begin
    Error('$RESOURCE ' + AToks[NameIdx].Text + ': нет AS "файл"');
    Exit;
  end;
  FileName := '';
  Angle := False;
  CloseIdx := NextSig(AToks, AsIdx + 1, ATo);
  if (CloseIdx >= 0) and (AToks[CloseIdx].Kind = tkString) then
    FileName := Copy(AToks[CloseIdx].Text, 2, Length(AToks[CloseIdx].Text) - 2)
  else if IsOp(AToks, CloseIdx, '<') then
  begin
    Angle := True;
    Inc(CloseIdx);
    while (CloseIdx <= ATo) and not IsOp(AToks, CloseIdx, '>') do
    begin
      FileName := FileName + AToks[CloseIdx].Text;
      Inc(CloseIdx);
    end;
  end;
  FileName := Trim(FileName);
  if FileName = '' then
  begin
    Error('$RESOURCE ' + AToks[NameIdx].Text + ': не указан файл');
    Exit;
  end;
  ResName := AToks[NameIdx].Up;
  // ./resource/x.bmp - от папки исходника, как у $INCLUDE
  if (Copy(FileName, 1, 2) = './') or (Copy(FileName, 1, 2) = '.\') then
    System.Delete(FileName, 1, 2);
  Found := ResolveInclude(FileName, Angle);
  ResIdx := FResources.IndexOfName(ResName);
  if ResIdx >= 0 then
  begin
    // тот же ресурс второй раз (sOpen в RQdebugger и в include)
    if FPass = 2 then
      Warn('$RESOURCE ' + AToks[NameIdx].Text + ': уже объявлен выше, это ' +
           'объявление ("' + FileName + '") пропущено');
    Exit;
  end;
  if (Found = '') and (FPass = 2) then
    Warn('$RESOURCE ' + AToks[NameIdx].Text + ': файл "' + FileName +
         '" не найден - ресурс будет пустым');
  FResources.Add(ResName + '=' + Found);
  VarRec := DeclareVar(AToks[NameIdx].Text, 'LONG', '', False, True, True);
  AOut := 'Const ' + VarRec.FbName + ' = ' +
          IntToStr(RqResourceBase + FResources.Count - 1) + ' ' + CommentOut(AOriginal);
end;

// Файл ресурсов для fbc: каждый $RESOURCE - RCDATA с номером
// RqResourceBase + порядковый номер (с 0), содержимое - файл как есть
// (BMP, ICO, WAV...). DLL и rqrt.bi берут его из exe по номеру.
function TRqFbConv.WriteResources: string;
var
  RcLines: TStringList;
  ResIdx: Integer;
  ResPath, RcText: string;
  RcStream: TFileStream;
begin
  Result := '';
  if FResources.Count = 0 then
    Exit;
  RcLines := TStringList.Create;
  try
    RcLines.Add('// $RESOURCE ' + ExtractFileName(FMainFile) + ' (RqToFb)');
    for ResIdx := 0 to FResources.Count - 1 do
    begin
      ResPath := FResources.ValueFromIndex[ResIdx];
      if ResPath = '' then
        RcLines.Add('// ' + FResources.Names[ResIdx] + ': file not found')
      else
        RcLines.Add(IntToStr(RqResourceBase + ResIdx) + ' RCDATA "' +
                    StringReplace(ResPath, '\', '/', [rfReplaceAll]) + '"');
    end;
    Result := IncludeTrailingPathDelimiter(FOpt.OutDir) +
              ChangeFileExt(ExtractFileName(FMainFile), '') + '_res.rc';
    try
      ForceDirectories(FOpt.OutDir);
      // строки через CR LF: GoRC (компилятор ресурсов fbc) с одним LF
      // ресурсов не видит
      RcText := '';
      for ResIdx := 0 to RcLines.Count - 1 do
        RcText := RcText + RcLines[ResIdx] + #13#10;
      RcStream := TFileStream.Create(Result, fmCreate);
      try
        RcStream.WriteBuffer(PChar(RcText)^, Length(RcText));
      finally
        RcStream.Free;
      end;
    except
      on E: Exception do
      begin
        Error('не удалось записать ' + Result + ': ' + E.Message);
        Result := '';
      end;
    end;
  finally
    RcLines.Free;
  end;
end;

function RqToFbConvert(const AMainFile: string; const AOptions: TRqFbOptions;
                       AMessages: TStrings; var AResult: TRqFbResult): Boolean;
var
  Conv: TRqFbConv;
begin
  Conv := TRqFbConv.Create(AOptions, AMessages);
  try
    Result := Conv.Run(AMainFile, AResult);
  finally
    Conv.Free;
  end;
end;

end.
