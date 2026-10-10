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
    // Подозрения на ошибку в самой программе (уровень Suspect): тело
    // процедуры не найдено, опечатка в имени, строка в число... Сборка
    // идёт, но программа, скорее всего, работает не так, как задумано
    SuspectCount: Integer;
    // файл ресурсов ($RESOURCE) для fbc; '' - ресурсов нет
    ResourceFile: string;
  end;

  // Ход перевода. Перевод идёт в два прохода по всем файлам программы
  // (главный и $INCLUDE): APass - 1 или 2, AFile - файл, который сейчас
  // читается, ALinesDone - строк пройдено в этом проходе, ALinesTotal -
  // строк всего (известно только во втором проходе, в первом 0).
  // Вызывается в начале каждого файла, через каждые 200 строк и в конце
  // прохода. Вернуть False - остановить перевод (результат - ошибка
  // "перевод остановлен").
  TRqFbProgress = function(APass: Integer; const AFile: string;
                           ALinesDone, ALinesTotal: Integer): Boolean of object;

// Перевести программу AMainFile. Сообщения - в AMessages. False - были
// ошибки (переведённые файлы всё равно записаны).
function RqToFbConvert(const AMainFile: string; const AOptions: TRqFbOptions;
                       AMessages: TStrings; var AResult: TRqFbResult): Boolean;

// То же с сообщениями о ходе перевода (окно хода сборки в unIDE).
// AProgress = nil - как RqToFbConvert.
function RqToFbConvertEx(const AMainFile: string; const AOptions: TRqFbOptions;
                         AMessages: TStrings; var AResult: TRqFbResult;
                         AProgress: TRqFbProgress): Boolean;

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
    'SENDMESSAGE POSTMESSAGE KILLMESSAGE MEMCPY MEMSET ' +
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
    'EXTRACTRESOURCE=RqExtractResource ' +
    // память, сообщения Windows, SHELL, QUICKSORT (rqrt.bi); VARPTR -
    // отдельно (RqVarPtr(@x), см. ProcessIdent)
    'VARPTR$=RqVarPtrStr MEMCPY=RqMemCpy MEMSET=RqMemSet MEMCMP=RqMemCmp ' +
    'SENDMESSAGE=RqSendMessage POSTMESSAGE=RqPostMessage ' +
    'KILLMESSAGE=RqKillMessage SHELL=RqShell QUICKSORT=RqQuickSort ' +
    'VARTYPE=RqVarType ' +
    // DLL (rqrt.bi): UNLOADLIBRARY ничего не делает - см. там
    'LIBRARYINST=RqLibraryInst UNLOADLIBRARY=RqUnloadLibrary SOUND=RqSound';

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
    'ONEDITING=VLONG;RLONG ONGETIMAGEINDEX=VLONG ONGETSELECTEDINDEX=VLONG ' +
    // QFORM OnClose (Action): caNone 0 - не закрывать, caHide 1, caFree 2,
    // caMinimize 3 (qform.html); у остальных классов OnClose без параметров
    'ONCLOSE=RLONG';

  // Библиотеки Windows, для которых у FreeBASIC есть библиотека импорта
  // (lib\win32, lib\win64: lib<имя>.dll.a): DECLARE ... LIB с ними -
  // Declare Lib, как раньше. Остальные DLL (свои DLL программы: fbsv.dll,
  // fb_regex.dll...) компоновщик ld не находит (cannot find -lfbsv.dll) -
  // их функции берутся при запуске, RqDllProc (rqrt.bi)
  RqImportLibText =
    'KERNEL32 USER32 GDI32 ADVAPI32 SHELL32 COMDLG32 COMCTL32 WININET WINMM ' +
    'WS2_32 WSOCK32 OLE32 OLEAUT32 SHLWAPI VERSION WINSPOOL MSVCRT NTDLL PSAPI ' +
    'CRYPT32 URLMON IMM32 UXTHEME MPR NETAPI32 OPENGL32 GLU32 MSIMG32 SETUPAPI ' +
    'IPHLPAPI WINHTTP RASAPI32 DWMAPI OLEDLG RPCRT4 SECUR32 USERENV WTSAPI32 ' +
    'POWRPROF HID DBGHELP GDIPLUS AVIFIL32 MSVFW32 VFW32 DSOUND DINPUT8 ODBC32';

  // Свойства, которые во всех классах rapidq_ref\ComponentAll.data -
  // STRING или массив STRING (Cell, ColumnCaption...: тип неявной
  // переменной Имя_Свойство, см. ProcessIdent; строка ли член объекта,
  // MemberIsString)
  RqStrPropText =
    'ADDCOLUMNS ADDLINES ADDPANELS ADDSECTIONS AGENT ALBUM ALIAS APPNAME APPVERSION ' +
    'ARTIST ATTRIBUTESASSTRING BMP BMPCLOSED BMPLEAF BMPMINUS BMPOPEN BMPPLUS ' +
    'CAPTION CELL CHANNELS CHILDCAPTION COLUMNCAPTION COLUMNLIST COMMENT COPYCAPTION ' +
    'COPYRIGHT CSVFILE CURRENTPATH CUTCAPTION DATE DATEALPHA DATEALPHAEU DATEEU DAYS ' +
    'DB DEFAULTEXT DEFAULTFONTNAME DIRECTORY DISPLAY DLGCAPTION DOCUMENTTITLE ' +
    'DOSFILENAME DRIVE DRIVER DRIVEROOT DRIVETYPESTRING ECHOSTRING EDITTEXT EMAIL ' +
    'EMPHASIS ERRORLANGUAGE ERRORMSG FIELDNAME FILE FILEATTRIBUTESASSTRING FILEDATE ' +
    'FILEDATEEU FILEID FILENAME FILES FILESYTEM FILETIME FILETIMEMS FILETITLE ' +
    'FILETYPE FLATBMPHANDLE FONTNAME FRAME_NAME FREESPACE GENRE HINT HOST HTMLTEXT ' +
    'INITIALDIR INPUTMASK INTENSITYSTEREO ITEMSEPARATOR KEYLISTNAME LANGUAGE ' +
    'LASTSTRINGERROR LAYER LEFTTEXT MASK MONTHS MS_STEREO NAME ORIGINAL OUTFILE ' +
    'OUTVAR PADDING PASSWORD PASSWORDCHAR PASTECAPTION PATH PATHFILENAME PROTECTION ' +
    'PROXYBYPASS PROXYNAME PTPOINT RIGHTTEXT SCONNECT SECTION SELECTALLCAPTION ' +
    'SELTEXT SEPARATOR SERIAL SERVER SHORTCUT SIMPLETEXT SSQL STRCONNECT STRDATA ' +
    'STRDAYOFWEEK STRMONTHOFYEAR STRSQL SUBITEM SYNTAXES SYSTEMDIR TAB TABLE TEMPDIR ' +
    'TEXT TEXTUREFILE TIME TIMEMS TIMEPOSITION TITLE TOTALSPACE TRACKTIME ' +
    'UNDOCAPTION USER VERSION WEB WINDIR YEAR';

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
    'POS HEX OCT BIN LCASE UCASE TRIM LTRIM RTRIM SPACE ' +
    // встроенные функции FreeBASIC с именами, которые в RapidQ свободны
    // (sadd в conversion.inc: fbc - "Duplicated definition"; переменная
    // strptr в RQdebugger; параметр dir у SysDir в Files.inc). У RapidQ
    // DIR$, CURDIR$, COMMAND$, DATE$, TIME$ - только с "$" (keyword.lst),
    // без "$" это обычные имена. FileCopy, FileLen, FileAttr,
    // FileDateTime у FreeBASIC - из file.bi, его rqrt.bi не подключает, -
    // не нужны. ExePath - нет: демо cls2test.bas пользуется им как ExePath
    // FreeBASIC
    'SADD STRPTR PROCPTR DIR CURDIR COMMAND DATE TIME INSTRREV ' +
    'WAIT ERL ERFN ERMN ASSERT ALLOCATE DEALLOCATE CALLOCATE REALLOCATE ' +
    'EXEC RESET LSET RSET WSTR WCHR ' +
    'WSPACE VALINT VALLNG VALUINT VALULNG CDBL CSNG CBYTE CUBYTE CSHORT ' +
    'CUSHORT CUINT CULNG CLNGINT CULNGINT CSIGN CUNSG CPTR ATAN2 LOC GETKEY ' +
    'MULTIKEY GETMOUSE SETMOUSE WINDOWTITLE SCREENRES SCREENSET BSAVE BLOAD ' +
    'IMAGECREATE IMAGEDESTROY PMAP DYLIBLOAD DYLIBSYMBOL DYLIBFREE OFFSETOF ' +
    'THREADCREATE MUTEXCREATE';

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
    'PROTECTED THIS BASE VAR LET CALL PEEK ' +
    // у Type с методами (свой компонент): fbc 1.10.1 error 238 "Fields
    // cannot be named as keywords" (rapidq2.inc, QFormEx: Virtual AS QFORM;
    // QBitmapEx: FUNCTION Pointer)
    'VIRTUAL ABSTRACT OVERRIDE POINTER';

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
    // Неявная Имя_Свойство из Имя.Свойство (DottedImplicit): Имя в
    // верхнем регистре; иначе ''
    DotBase: string;
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
    // DECLARE ... LIB: вид каждого параметра, по символу: N - число ByVal,
    // R - число ByRef, S - STRING (ZString Ptr), O - остальное. По нему
    // вызов приводит аргументы к тому, что ждёт функция DLL (WrapLibArgs).
    LibKinds: string;
    // DECLARE ... LIB библиотеки без библиотеки импорта FreeBASIC (своя
    // DLL программы): указатель Dim Shared, адрес - RqDllProc при запуске
    DynLib: Boolean;
    // Есть обращение (вызов, адрес, обработчик события) - MissingBodies
    Used: Boolean;
    // FUNCTION читает RESULT (result = result & ...): значение функции
    // FreeBASIC прочитать нельзя, оно ведётся в локальной rq_result
    ResultRead: Boolean;
    // Первый DECLARE без LIB в этом проходе: номер прохода и место. Второй
    // такой же DECLARE (rapidq2.inc: DECLARE SUB OnClose_EventTemplate у
    // QDockForm и у ComPort) fbc отвергает (error 4) - он закомментируется
    DeclPass: Integer;
    DeclAt: string;
    // То же для DECLARE с LIB. Повторный с другими параметрами (rapidq2.inc:
    // GlobalMemoryStatus(lpBuffer As MEMORYSTATUS), программа - то же с
    // T_MEMORYSTATUS) fbc отвергает (error 4): второй закомментируется, а
    // параметры первого, которые у них различаются и оба ByRef, - As Any
    // (LibMerged, собирается в первом проходе), чтобы подходили вызовы обоих.
    LibDeclPass: Integer;
    LibDeclAt: string;
    LibDeclParams: string;
    LibMerged: string;
  end;

  // Таблица ИМЯ -> значение с поиском делением пополам. Заменяет списки
  // "ИМЯ=значение" с IndexOfName там, где поиск идёт на каждое слово
  // программы ($DEFINE, члены классов): IndexOfName перебирает список
  // целиком и сравнивает строки без учёта регистра, а в Delphi 7 под
  // Windows это вызов CompareString на каждую строку списка. Имена - в
  // верхнем регистре, сравнение с учётом регистра.
  TRqNameValue = class
  public
    Value: string;
  end;

  // Сортированный список, сравнение по кодам символов (CompareStr), а не
  // AnsiCompareText: имена уже в верхнем регистре, а сравнение без учёта
  // регистра с языковыми правилами в Delphi 7 под Windows - вызов
  // CompareString на каждое сравнение
  TRqOrdList = class(TStringList)
  protected
{$IFDEF FPC}
    function DoCompareText(const AText1, AText2: string): PtrInt; override;
{$ELSE}
    function CompareStrings(const AText1, AText2: string): Integer; override;
{$ENDIF}
  end;

  TRqNameMap = class
  private
    FNames: TRqOrdList;   // Sorted; Objects - TRqNameValue
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function Count: Integer;
    // Номер имени, -1 - нет
    function IndexOf(const AName: string): Integer;
    function ValueAt(AIdx: Integer): string;
    // Значение по имени; нет имени - ''
    function Get(const AName: string): string;
    // Добавить или заменить значение
    procedure Put(const AName, AValue: string);
    procedure Remove(const AName: string);
    // Пары "ИМЯ=значение" через пробел (RqFuncMapText и подобные)
    procedure LoadPairs(const APairs: string);
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
    MethParams: TStringList;  // ИМЯ=параметры метода FreeBASIC (M, N)
    CbThunks: TStringList;    // методы, адрес которых берёт CODEPTR (верхний регистр)
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
    FTypeDefs: TStringList;       // ИМЯ=файл(строка) первого объявления TYPE
    FDefPlaces: TRqNameMap;       // вид|область|ИМЯ -> файл(строка) первого объявления
    FDefinePlaces: TRqNameMap;    // $DEFINE ИМЯ -> файл(строка), в текущем проходе
    FCurTypePlace: string;        // файл(строка) строки TYPE текущего компонента
    FCurProcPlace: string;        // файл(строка) заголовка текущей SUB/FUNCTION/метода
    FLabels: TStringList;
    // Где метка: "ПРОЦЕДУРА|МЕТКА=файл(строка)" (процедура '' - модуль) -
    // проверка GOTO/GOSUB, CheckLabel
    FLabelPlaces: TStringList;
    FRedims: TStringList;         // имена, у которых есть REDIM
    FDefines: TRqNameMap;         // NAME -> замена
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
    FFuncMap: TRqNameMap;         // ИМЯ$ -> функция rqrt.bi
    FMemberMap: TRqNameMap;       // СВОЙСТВО -> имя в .bi
    FIndexedSet: TStringList;     // СВОЙСТВО=метод записи
    FEventSigs: TStringList;      // СОБЫТИЕ=типы параметров обработчика
    FHandlerEvents: TStringList;  // ПРОЦЕДУРА=СОБЫТИЕ (из Объект.OnXxx = Процедура)
    FHandlerProcs: TStringList;   // процедуры - обработчики событий
    FBinds: TStringList;          // ПЕРЕМЕННАЯ=процедура (BIND ... TO)
    FSkipBody: Boolean;           // тело функции-обхода RapidQ пропускается
    // Ход перевода (RqToFbConvertEx): строк пройдено в этом проходе, строк
    // в первом проходе, значение FPassLines при последнем сообщении;
    // FAborted - получатель вернул False
    FProgress: TRqFbProgress;
    FPassLines: Integer;
    FPass1Lines: Integer;
    FProgLast: Integer;
    FAborted: Boolean;
    FParamAliases: string;        // от ParseParams: " : Dim ByRef ..."
    FLibKinds: string;            // от ParseParams: виды параметров DECLARE ... LIB
    FClassMembers: TStringList;   // КЛАСС.ИМЯ=P|M|E (RqClassMembersText)
    FAllMembers: TRqNameMap;      // ИМЯ -> P|M|E по всем классам
    FCreateStack: TStringList;    // CREATE: ИмяОбъекта=КЛАСС, внутренний - последний
    FCurFile: string;
    FCurLine: Integer;
    FCurProc: TRqProc;
    FInType: Boolean;
    FPlainType: string;           // запись TYPE (не свой компонент) - имя
    FFixBodies: string;           // свойства полей STRING*N - после END TYPE
    FCreateDepth: Integer;
    // FOR ... NEXT: открытые циклы. Счётчик - поле или элемент массива
    // (rapidq2.inc, QListViewEx: FOR THIS.lx = ...) у FreeBASIC быть не
    // может (error 52) - такой FOR переводится в WHILE ... WEND
    // (ProcessFor), его NEXT - в шаг и WEND
    FForTargets: array of string;   // счётчик (текст RapidQ); '' - обычный FOR
    FForSteps: array of string;     // имя переменной шага
    FForCount: Integer;
    FTypeCheck: Boolean;
    FEscape: Boolean;
    FDefaultType: string;
    FByRefDefault: Boolean;
    FConds: array of TCondRec;
    FAppType: string;
    FHasGui: Boolean;
    FErrors: Integer;
    FWarnings: Integer;
    FSuspects: Integer;
    FLostLines: Integer;          // переводы строк, убранные сборкой заново
    FSourceMode: string;          // '$RQFB SMART|COMPAT из исходника
    FLineIsLabel: Boolean;
    // В начало программы (MainHeader): DECLARE ... LIB и CONST с числом
    // или строкой (HoistLine). RapidQ позволяет обратиться к ним раньше
    // объявления (QDebug в RAPIDQ.INC - FormatMessage и FORMAT_MESSAGE_
    // FROM_SYSTEM из ComPort.cmp, подключённого позже); FreeBASIC - нет.
    // Текст - из первого прохода, на своём месте строка - комментарий.
    FHoistKeys: TRqNameMap;       // 'C|ИМЯ' / 'D|ИМЯ' - уже вынесенные
    FHoistConsts: TStringList;
    FHoistDecls: TStringList;
    FLibParams: Boolean;          // параметры DECLARE ... LIB (STRING - указатель)
    FInlineIf: Boolean;           // в строке однострочный IF (после THEN есть оператор)
    // Вложенность блоков (WITH, FOR, DO, WHILE, SELECT, IF ... THEN) вне
    // SUB/FUNCTION в текущем файле - DIM внутри них (TrackModBlock,
    // ProcessDim)
    FModBlocks: Integer;
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
    procedure ErrorOnce(const AKey, AText: string);
    procedure Suspect(const AText: string);
    procedure SuspectOnce(const AKey, AText: string);
    procedure NoteDef(const AKey, AWhat: string);
    procedure MergeDottedProcs(var AToks: TToks);
    function DefScope(const AScope: string): string;
    function CondActive: Boolean;

    // Разбор строки
    procedure Lex(const AText: string; var AToks: TToks);
    function NextSig(const AToks: TToks; AFrom, ATo: Integer): Integer;
    function PrevSig(const AToks: TToks; AFrom: Integer): Integer;
    function MatchParen(const AToks: TToks; AOpen, ATo: Integer): Integer;
    function IsOp(const AToks: TToks; AIdx: Integer; const AOp: string): Boolean;
    function IsWord(const AToks: TToks; AIdx: Integer; const AWord: string): Boolean;
    function ApplyDefines(const AText: string): string;
    function DefineKeptInType(const AToks: TToks; AIdx, AFirst: Integer): Boolean;
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
    procedure WrapLibArgs(var AToks: TToks; AFrom, ATo: Integer; AProc: TRqProc);
    function IsStrVarRef(const AToks: TToks; AFrom, ATo: Integer): Boolean;
    procedure ProcessIdent(var AToks: TToks; AIdx, ATo: Integer);
    function  HasChrZero(const AToks: TToks; AFrom, ATo: Integer): Boolean;
    function  IsImportLib(const ALibName: string): Boolean;
    procedure TrackModBlock(const AToks: TToks; AFirst, ATo: Integer);
    procedure CheckLabel(const AToks: TToks; AFirst, ATo: Integer);
    function  MemberIsString(const AToks: TToks; AIdx: Integer): Boolean;
    procedure WrapMemberStrIndex(var AToks: TToks; AIdx, ATo: Integer);
    function  ProcessSwap(var AToks: TToks; AFirst, ATo: Integer): Boolean;
    function  TranslateFragment(const AText: string): string;
    function  DottedImplicit(var AToks: TToks; AIdx, ADotIdx, ATo: Integer): Boolean;
    procedure ProcessAssignOrCall(var AToks: TToks; AFrom, ATo: Integer);
    procedure ProcessDim(var AToks: TToks; AFrom, ATo: Integer);
    procedure ProcessDef(var AToks: TToks; AFrom, ATo: Integer);
    function InitIsConst(const AToks: TToks; AFrom, ATo: Integer): Boolean;
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
    procedure ProcessNext(var AToks: TToks; AFrom, ATo: Integer);
    function GosubScope: string;
    procedure GosubVarNames(const AScope: string; var ASpName, AStkName: string);
    procedure ProcessGosub(var AToks: TToks; AFrom, ATo: Integer);
    procedure ProcessReturn(var AToks: TToks; AFrom, ATo: Integer);
    procedure ProcessIncDec(var AToks: TToks; AFrom, ATo: Integer);
    procedure ProcessQuickSort(var AToks: TToks; AFrom, ATo: Integer);
    procedure ProcessInitArray(var AToks: TToks; AFrom, ATo: Integer);
    function ArgIsRecord(const AToks: TToks; AFrom, ATo: Integer): Boolean;
    function TopComma(const AToks: TToks; AFrom, ATo: Integer): Integer;
    procedure MemRecordArgs(var AToks: TToks; AHeadIdx, ATo: Integer);
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
    procedure Report(const AFile: string);
    function MainHeader: string;
    function MissingBodies: string;
    procedure HoistLine(const AToks: TToks; AFirstIdx: Integer;
                        const ASource: string; var AOut: string);
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
    function CodePtrMethod(var AToks: TToks; AIdx, AOpen, AClose: Integer): Boolean;
    function BindMethod(var AToks: TToks; AFrom, AToIdx, AOwnerIdx, ATo: Integer;
                        const AKeyUp: string): Boolean;
    procedure AddCodePtrThunks;
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

// ---------------------------------------------------------------------------
//  TRqNameMap

{$IFDEF FPC}
function TRqOrdList.DoCompareText(const AText1, AText2: string): PtrInt;
begin
  Result := CompareStr(AText1, AText2);
end;
{$ELSE}
function TRqOrdList.CompareStrings(const AText1, AText2: string): Integer;
begin
  Result := CompareStr(AText1, AText2);
end;
{$ENDIF}

constructor TRqNameMap.Create;
begin
  inherited Create;
  FNames := TRqOrdList.Create;
  FNames.CaseSensitive := True;
  FNames.Sorted := True;
  FNames.Duplicates := dupIgnore;
end;

destructor TRqNameMap.Destroy;
begin
  Clear;
  FNames.Free;
  inherited Destroy;
end;

procedure TRqNameMap.Clear;
var
  ItemIdx: Integer;
begin
  for ItemIdx := 0 to FNames.Count - 1 do
    FNames.Objects[ItemIdx].Free;
  FNames.Clear;
end;

function TRqNameMap.Count: Integer;
begin
  Result := FNames.Count;
end;

function TRqNameMap.IndexOf(const AName: string): Integer;
begin
  if not FNames.Find(AName, Result) then
    Result := -1;
end;

function TRqNameMap.ValueAt(AIdx: Integer): string;
begin
  Result := TRqNameValue(FNames.Objects[AIdx]).Value;
end;

function TRqNameMap.Get(const AName: string): string;
var
  ItemIdx: Integer;
begin
  Result := '';
  if FNames.Find(AName, ItemIdx) then
    Result := TRqNameValue(FNames.Objects[ItemIdx]).Value;
end;

procedure TRqNameMap.LoadPairs(const APairs: string);
var
  Rest, Pair: string;
  SpacePos, EqPos: Integer;
begin
  Rest := Trim(APairs);
  while Rest <> '' do
  begin
    SpacePos := Pos(' ', Rest);
    if SpacePos = 0 then
    begin
      Pair := Rest;
      Rest := '';
    end
    else
    begin
      Pair := Copy(Rest, 1, SpacePos - 1);
      Rest := TrimLeft(Copy(Rest, SpacePos + 1, MaxInt));
    end;
    EqPos := Pos('=', Pair);
    if EqPos > 1 then
      Put(Copy(Pair, 1, EqPos - 1), Copy(Pair, EqPos + 1, MaxInt));
  end;
end;

procedure TRqNameMap.Put(const AName, AValue: string);
var
  ItemIdx: Integer;
  Holder: TRqNameValue;
begin
  if FNames.Find(AName, ItemIdx) then
    TRqNameValue(FNames.Objects[ItemIdx]).Value := AValue
  else
  begin
    Holder := TRqNameValue.Create;
    Holder.Value := AValue;
    FNames.AddObject(AName, Holder);
  end;
end;

procedure TRqNameMap.Remove(const AName: string);
var
  ItemIdx: Integer;
begin
  if FNames.Find(AName, ItemIdx) then
  begin
    FNames.Objects[ItemIdx].Free;
    FNames.Delete(ItemIdx);
  end;
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
  MethParams := TStringList.Create;
  CbThunks := TStringList.Create;
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
  MethParams.Free;
  CbThunks.Free;
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
// Продолжение строки, приклеенное к слову: "lFlags As Long_" (Files.inc,
// DECLARE InternetOpen). Обычно "_" после буквы - часть имени, поэтому
// продолжением считается только "_" после слова типа или ключевого слова,
// которыми переменная называться не может, и только в конце строки.
function IsGlueWord(const AWord: string): Boolean;
const
  GlueWords = ' BYTE SHORT WORD INTEGER LONG DWORD SINGLE DOUBLE STRING ' +
              'VARIANT AS AND OR XOR NOT MOD THEN ELSE TO STEP BYVAL BYREF ';
begin
  Result := (AWord <> '') and (Pos(' ' + UpperCase(AWord) + ' ', GlueWords) > 0);
end;

// После позиции AFrom до конца физической строки - только пробелы или
// комментарий
function LineRestBlank(const AText: string; AFrom: Integer): Boolean;
var
  CharIdx: Integer;
begin
  Result := True;
  for CharIdx := AFrom to Length(AText) do
    case AText[CharIdx] of
      ' ', #9:
        ;
      #13, #10, '''':
        Exit;
    else
      begin
        Result := False;
        Exit;
      end;
    end;
end;

// Строка в кавычках не закрыта к концу текста и кончается на "_"
// (RQdebugger: OpenDialog.Filter = "1.All Files *.*|*.*|_ с продолжением
// на следующих строках). ACutPos - позиция этого "_". Кавычки считаются
// с начала всего текста: он может быть уже собран из нескольких строк.
function StrContinues(const AText: string; out ACutPos: Integer): Boolean;
var
  CharIdx, LastIdx: Integer;
  InQuote: Boolean;
begin
  Result := False;
  ACutPos := 0;
  InQuote := False;
  for CharIdx := 1 to Length(AText) do
    if AText[CharIdx] = '"' then
      InQuote := not InQuote
    else if (AText[CharIdx] = '''') and not InQuote then
      Exit;
  if not InQuote then
    Exit;
  LastIdx := Length(AText);
  while (LastIdx > 0) and (AText[LastIdx] in [' ', #9, #13, #10]) do
    Dec(LastIdx);
  if (LastIdx = 0) or (AText[LastIdx] <> '_') then
    Exit;
  ACutPos := LastIdx;
  Result := True;
end;

function EndsWithContinue(const AText: string): Boolean;
var
  CharIdx, LineStart, LastIdx, WordStart: Integer;
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
  // перед "_" - не часть имени (пробел, кавычка, скобка...); или "_"
  // приклеен к слову типа / ключевому слову (Long_)
  if (LastIdx > LineStart) and
     (AText[LastIdx - 1] in ['A'..'Z', 'a'..'z', '0'..'9', '_']) then
  begin
    WordStart := LastIdx - 1;
    while (WordStart > LineStart) and
          (AText[WordStart - 1] in ['A'..'Z', 'a'..'z', '0'..'9', '_']) do
      Dec(WordStart);
    if not IsGlueWord(Copy(AText, WordStart, LastIdx - WordStart)) then
      Exit;
  end;
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
  MemberText, MemberName: string;
begin
  inherited Create;
  FOpt := AOptions;
  FMsgs := AMessages;
  FVars := TStringList.Create;
  FVars.Sorted := True;
  FProcs := TStringList.Create;
  FProcs.Sorted := True;
  FTypes := TStringList.Create;
  FTypeDefs := TStringList.Create;
  FDefPlaces := TRqNameMap.Create;
  FDefinePlaces := TRqNameMap.Create;
  FTypes.Sorted := True;
  FTypes.Duplicates := dupIgnore;
  FLabels := TStringList.Create;
  FLabels.Sorted := True;
  FLabels.Duplicates := dupIgnore;
  FLabelPlaces := TStringList.Create;
  FGosubSites := TStringList.Create;
  FRedims := TStringList.Create;
  FRedims.Sorted := True;
  FRedims.Duplicates := dupIgnore;
  FDefines := TRqNameMap.Create;
  FHoistKeys := TRqNameMap.Create;
  FHoistConsts := TStringList.Create;
  FHoistDecls := TStringList.Create;
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
  FFuncMap := TRqNameMap.Create;
  FFuncMap.LoadPairs(RqFuncMapText);
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
  FAllMembers := TRqNameMap.Create;
  for ClassIdx := 0 to FClassMembers.Count - 1 do
  begin
    MemberText := FClassMembers[ClassIdx];
    MemberText := Copy(MemberText, Pos('.', MemberText) + 1, MaxInt);
    MemberName := Copy(MemberText, 1, Pos('=', MemberText) - 1);
    if FAllMembers.IndexOf(MemberName) < 0 then
      FAllMembers.Put(MemberName, Copy(MemberText, Pos('=', MemberText) + 1, MaxInt))
    else if Copy(MemberText, Length(MemberText), 1) = 'P' then
      // свойство важнее метода с тем же именем
      FAllMembers.Put(MemberName, 'P');
  end;
  FIndexedSet := TStringList.Create;
  FIndexedSet.Text := StringReplace(RqIndexedSetText, ' ', CrLf, [rfReplaceAll]);
  FMemberMap := TRqNameMap.Create;
  FMemberMap.LoadPairs(RqMemberMapText);
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
  FTypeDefs.Free;
  FDefPlaces.Free;
  FDefinePlaces.Free;
  FLabels.Free;
  FLabelPlaces.Free;
  FGosubSites.Free;
  FRedims.Free;
  FDefines.Free;
  FHoistKeys.Free;
  FHoistConsts.Free;
  FHoistDecls.Free;
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

// Подозрение на ошибку в программе RapidQ (не в переводе): перевод и
// сборка идут, но место, скорее всего, - баг программы. Свой уровень,
// "Suspect", чтобы unIDE показал такие строки отдельно от обычных
// предупреждений
procedure TRqFbConv.Suspect(const AText: string);
begin
  if FPass = 2 then
    Inc(FSuspects);
  Msg('Suspect', AText);
end;

procedure TRqFbConv.SuspectOnce(const AKey, AText: string);
var
  Found: Integer;
begin
  if FPass <> 2 then
    Exit;
  if FWarnedNames.Find(AKey, Found) then
    Exit;
  FWarnedNames.Add(AKey);
  Suspect(AText);
end;

// Объявление имени (AKey - вид|область|ИМЯ). Первый проход запоминает место
// первого объявления, второй - на повторном объявлении в другом месте
// пишет "already defined" с местом первого (rc.exe на повторный CONST
// выдаёт "CONST variable ... already defined"). Уровень Suspect: перевод
// идёт дальше, но это, скорее всего, ошибка программы.
procedure TRqFbConv.NoteDef(const AKey, AWhat: string);
var
  Here, First: string;
begin
  Here := FCurFile + '(' + IntToStr(FCurLine) + ')';
  if FPass = 1 then
  begin
    if FDefPlaces.IndexOf(AKey) < 0 then
      FDefPlaces.Put(AKey, Here);
    Exit;
  end;
  First := FDefPlaces.Get(AKey);
  if (First <> '') and (First <> Here) then
    Suspect(AWhat + ' already defined - первое объявление: ' + First);
end;

// Область имени для NoteDef: у локальных - место заголовка процедуры, а не
// её имя (FUNCTION Screen.MouseSwap и Screen.MouseButtons в rapidq2.inc
// переводчик ведёт под одним именем SCREEN; одноимённые методы двух TYPE)
function TRqFbConv.DefScope(const AScope: string): string;
begin
  if AScope = '' then
    Result := ''
  else
    Result := AScope + '@' + FCurProcPlace;
end;

// SUB / FUNCTION с точкой в имени (rapidq2.inc: FUNCTION Screen.MousePresent,
// FUNCTION Application.Path, FUNCTION Screen.EnumResolution(ListView AS
// QLISTBOX)) - так RapidQ добавляет "методы" встроенным объектам; имя -
// целиком "Screen.MousePresent" (Screen.CaptureToBMP = retrn внутри -
// результат функции). Слова Имя . Имя склеиваются в одно слово: в заголовке
// SUB / FUNCTION / DECLARE - всегда, в остальном тексте - если такая
// процедура есть. Дальше это обычная процедура (во FreeBASIC - Screen_MousePresent).
procedure TRqFbConv.MergeDottedProcs(var AToks: TToks);
var
  TokIdx, DotIdx, NameIdx, FirstIdx, KindIdx: Integer;
  JoinedUp: string;
  IsHeader: Boolean;
begin
  FirstIdx := NextSig(AToks, 0, High(AToks));
  if FirstIdx < 0 then
    Exit;
  KindIdx := FirstIdx;
  if IsWord(AToks, FirstIdx, 'DECLARE') then
    KindIdx := NextSig(AToks, FirstIdx + 1, High(AToks));
  for TokIdx := 0 to High(AToks) - 2 do
  begin
    if AToks[TokIdx].Kind <> tkIdent then
      Continue;
    DotIdx := TokIdx + 1;
    NameIdx := TokIdx + 2;
    if not IsOp(AToks, DotIdx, '.') or (AToks[NameIdx].Kind <> tkIdent) then
      Continue;
    // перед словом - не точка (This.Form.Show не трогаем)
    if (TokIdx > 0) and IsOp(AToks, TokIdx - 1, '.') then
      Continue;
    JoinedUp := AToks[TokIdx].Up + '.' + AToks[NameIdx].Up;
    IsHeader := (KindIdx >= 0) and (NextSig(AToks, KindIdx + 1, High(AToks)) = TokIdx) and
                (IsWord(AToks, KindIdx, 'SUB') or IsWord(AToks, KindIdx, 'FUNCTION') or
                 IsWord(AToks, KindIdx, 'SUBI') or IsWord(AToks, KindIdx, 'FUNCTIONI')) and
                (FCurType = nil);
    if not IsHeader and (FindProc(JoinedUp) = nil) then
      Continue;
    AToks[TokIdx].Text := AToks[TokIdx].Text + '.' + AToks[NameIdx].Text;
    AToks[TokIdx].Up := JoinedUp;
    AToks[TokIdx].OutText := AToks[TokIdx].Text;
    AToks[DotIdx].Kind := tkSpace;
    AToks[DotIdx].Text := '';
    AToks[DotIdx].OutText := '';
    AToks[NameIdx].Kind := tkSpace;
    AToks[NameIdx].Text := '';
    AToks[NameIdx].OutText := '';
  end;
end;

// Ошибка один раз по ключу AKey
procedure TRqFbConv.ErrorOnce(const AKey, AText: string);
var
  Found: Integer;
begin
  if FPass <> 2 then
    Exit;
  if FWarnedNames.Find(AKey, Found) then
    Exit;
  FWarnedNames.Add(AKey);
  Error(AText);
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

  // Слово с Pos0 кончается на "_", без "_" - слово типа или ключевое
  // (IsGlueWord), дальше до конца строки пусто: Pos1 - на этом "_"
  function GluedEnd: Boolean;
  var
    WordEnd: Integer;
  begin
    Result := False;
    WordEnd := Pos0;
    while (WordEnd + 1 <= TextLen) and IsIdentChar(AText[WordEnd + 1]) do
      Inc(WordEnd);
    if (WordEnd > Pos0) and (AText[WordEnd] = '_') and
       IsGlueWord(Copy(AText, Pos0, WordEnd - Pos0)) and
       LineRestBlank(AText, WordEnd + 1) then
    begin
      Pos1 := WordEnd;
      Result := True;
    end;
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
    else if IsIdentStart(Ch) and GluedEnd then
    begin
      // "Long_" в конце строки: слово, затем продолжение (IsGlueWord)
      Add(tkIdent, Pos0, Pos1 - 1);
      Pos0 := Pos1;
      while (Pos1 + 1 <= TextLen) and (AText[Pos1 + 1] in [' ', #9, #13, #10]) do
        Inc(Pos1);
      Add(tkSpace, Pos0, Pos1);
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
          ((Ch = '>') and (AText[Pos1 + 1] = '=')) or
          ((Ch = '=') and (AText[Pos1 + 1] in ['>', '<']))) then
        Inc(Pos1);
      Add(tkOp, Pos0, Pos1);
      // => и =< - как >= и <= (так в QSpinEdit.inc: IF .Value => .MaxValue;
      // в operators.html - только >= и <=)
      if (AToks[Count - 1].Text = '=>') or (AToks[Count - 1].Text = '=<') then
      begin
        AToks[Count - 1].Text := AToks[Count - 1].Text[2] + '=';
        AToks[Count - 1].Up := AToks[Count - 1].Text;
        AToks[Count - 1].OutText := AToks[Count - 1].Text;
      end;
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
// Внутри TYPE имя члена $DEFINE не заменяет. Тест пользователя в RapidQ
// 2026-10-10 (tests/research/DefCase1.bas, DefCase2.bas): $DEFINE регистр
// не различает (TRANSPARENT, Transparent, transparent - все 1), но с
// $DEFINE TRANSPARENT 1 поле "Transparent AS INTEGER" в TYPE ... EXTENDS
// компилируется и DefObj.Transparent = 7 печатает 7. Так в rapidq2.inc:
// $DEFINE TRANSPARENT 1, поле Transparent у QFormEx и у QMenu, в
// CONSTRUCTOR - "Transparent = True".
// Не заменяется: объявление поля (первое слово строки, за ним AS или "(")
// и имя, которое уже есть среди членов этого TYPE. Вне TYPE и в других
// местах TYPE - как раньше; как RapidQ поступает там, не проверялось.
// Внутри CREATE ... END CREATE не заменяется первое слово строки, если это
// свойство или метод класса объекта (RQdebugger853-8RQ.bas: с $DEFINE
// TRANSPARENT 1 из rapidq2.inc строка "Transparent = 1" у QLABEL давала
// "1 = 1", fbc error 146). Что RapidQ делает здесь сам, не проверялось:
// программа в RapidQ компилируется.
function TRqFbConv.DefineKeptInType(const AToks: TToks; AIdx, AFirst: Integer): Boolean;
var
  NextIdx: Integer;
  ClassUp: string;
begin
  Result := False;
  if (AIdx = AFirst) and (FCreateStack <> nil) and (FCreateStack.Count > 0) then
  begin
    ClassUp := UpperCase(FCreateStack.ValueFromIndex[FCreateStack.Count - 1]);
    if FindTypeInfo(ClassUp) <> nil then
      ClassUp := FindTypeInfo(ClassUp).BaseClass;
    if MemberKind(ClassUp, AToks[AIdx].Up) <> #0 then
    begin
      Result := True;
      Exit;
    end;
  end;
  if (FCurType = nil) and not FInType then
    Exit;
  if AIdx = AFirst then
  begin
    NextIdx := NextSig(AToks, AIdx + 1, High(AToks));
    if IsWord(AToks, NextIdx, 'AS') or IsOp(AToks, NextIdx, '(') then
    begin
      Result := True;
      Exit;
    end;
  end;
  if (FCurType <> nil) and (FCurType.Kind(AToks[AIdx].Up) <> #0) then
    Result := True;
end;

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
      if not IsOp(Toks, PrevIdx, '.') and not DefineKeptInType(Toks, TokIdx, FirstIdx) then
      begin
        DefIdx := FDefines.IndexOf(Toks[TokIdx].Up);
        if DefIdx >= 0 then
        begin
          Result := Result + FDefines.ValueAt(DefIdx);
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
  // Screen.MousePresent (SUB / FUNCTION с точкой в имени) -> Screen_MousePresent
  if Pos('.', Result) > 0 then
    Result := StringReplace(Result, '.', '_', [rfReplaceAll]);
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
  else if ARqType = 'VARIANT' then
    Result := 'RqVariant'   // rqrt.bi: число, дробное или строка
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

// Перем ++ (оператор RapidQ, loops.html: I++) -> Перем += 1; Перем --
// (rapidq2.inc, QFormMDI.inc: QFormMDI.ChildCount--) -> Перем -= 1
function TRqFbConv.ProcessPlusPlus(var AToks: TToks; AFirst, ATo: Integer): Boolean;
var
  LastIdx, PlusIdx, TargetEnd: Integer;
  VarRec: TRqVar;
  OpChar: string;
begin
  Result := False;
  LastIdx := PrevSig(AToks, ATo);
  if IsOp(AToks, LastIdx, '+') then
    OpChar := '+'
  else if IsOp(AToks, LastIdx, '-') then
    OpChar := '-'
  else
    Exit;
  PlusIdx := PrevSig(AToks, LastIdx - 1);
  if not IsOp(AToks, PlusIdx, OpChar) or (PlusIdx <= AFirst) then
    Exit;
  TargetEnd := PrevSig(AToks, PlusIdx - 1);
  if not ((AToks[TargetEnd].Kind = tkIdent) or IsOp(AToks, TargetEnd, ')')) then
    Exit;
  ProcessExpr(AToks, AFirst, TargetEnd);
  VarRec := FindVar(AToks[AFirst].Up);
  if VarRec <> nil then
    VarRec.Assigned := True;
  AToks[PlusIdx].OutText := OpChar + '= 1';
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
              IsOp(AToks, PrevSig(AToks, TokIdx - 1), '.') then
        Result := MemberIsString(AToks, TokIdx)
      else if AToks[TokIdx].Kind = tkIdent then
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

// Член объекта Владелец.Член (AIdx - на члене, перед ним "."): строковый?
//   - суффикс $;
//   - This.Член в методе своего компонента или Объект.Член, где Объект -
//     свой компонент (TYPE ... EXTENDS): по типу члена из объявления
//     (QFILEDIALOG.INC: .Files(0) = .FileName - .FileTitle, FileName AS
//     STRING);
//   - Объект класса RapidQ, а член - свойство, которое во всех классах
//     STRING (RqStrPropText: Text, Caption, ...).
// Иначе (запись TYPE, неизвестный владелец, цепочка a.b.c) - нет.
function TRqFbConv.MemberIsString(const AToks: TToks; AIdx: Integer): Boolean;
var
  DotIdx, OwnerIdx: Integer;
  MemberUp, OwnerType: string;
  Info: TRqTypeInfo;
  VarRec: TRqVar;
begin
  MemberUp := AToks[AIdx].Up;
  Result := SuffixOf(MemberUp) = '$';
  if Result then
    Exit;
  DotIdx := PrevSig(AToks, AIdx - 1);
  OwnerIdx := PrevSig(AToks, DotIdx - 1);
  if (OwnerIdx < 0) or (AToks[OwnerIdx].Kind <> tkIdent) or
     IsOp(AToks, PrevSig(AToks, OwnerIdx - 1), '.') then
    Exit;
  Info := nil;
  OwnerType := '';
  if (AToks[OwnerIdx].Up = 'THIS') and (FCurType <> nil) then
    Info := FCurType
  else
  begin
    VarRec := FindVar(AToks[OwnerIdx].Up);
    if VarRec = nil then
      Exit;
    OwnerType := UpperCase(VarRec.RqType);
    Info := FindTypeInfo(OwnerType);
  end;
  if Info <> nil then
  begin
    if Info.MemberType.IndexOfName(MemberUp) >= 0 then
    begin
      Result := UpperCase(Info.MemberType.Values[MemberUp]) = 'STRING';
      Exit;
    end;
    // член базового класса RapidQ
    OwnerType := Info.BaseClass;
  end;
  if InList(FObjClasses, OwnerType) then
    Result := Pos(' ' + MemberUp + ' ', ' ' + RqStrPropText + ' ') > 0;
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
            // RESULT в FUNCTION - значение функции, а не неявная
            // переменная result модуля
            if (AToks[TokIdx].Up = 'RESULT') and not VarRec.Explicit and
               (FCurProc <> nil) and FCurProc.IsFunc then
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
  MergeDottedProcs(Toks);
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
      (FirstUp = '$ENDIF') or (FirstUp = '$IF')) then
  begin
    AOut := CommentOut(AText);
    // #if выражение (строки заголовка C в блоке-комментарии brem 0 ... erem,
    // QFileDialogDoc.inc: #if (_WIN32_WINNT >= 0x0500) ... #endif): выражение
    // не вычисляется, блок пропускается, как неопределённое условие в C.
    // Без этого #endif закрывал чужой блок ($ENDIF без $IFDEF дальше)
    if FirstUp = '$IF' then
    begin
      if CondActive then
        Warn(Trim(RawText(Toks, FirstIdx, High(Toks))) +
             ': условие #if/$IF не вычисляется - блок до #endif пропущен');
      Cond.ParentActive := CondActive;
      Cond.Active := False;
      Cond.ElseSeen := False;
      SetLength(FConds, Length(FConds) + 1);
      FConds[High(FConds)] := Cond;
    end
    else if (FirstUp = '$IFDEF') or (FirstUp = '$IFNDEF') then
    begin
      NameIdx := NextSig(Toks, FirstIdx + 1, High(Toks));
      CondName := '';
      if NameIdx >= 0 then
        CondName := Toks[NameIdx].Up;
      IsDefined := FDefines.IndexOf(CondName) >= 0;
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
    if FCurProc <> nil then
      NoteDef('L|' + DefScope(FCurProc.Name) + '|' + FirstUp, 'Метка ' + Toks[FirstIdx].Text)
    else
      NoteDef('L||' + FirstUp, 'Метка ' + Toks[FirstIdx].Text);
    if FPass = 1 then
    begin
      FLabels.Add(FirstUp);
      if FCurProc <> nil then
        FLabelPlaces.Add(FCurProc.Name + '|' + FirstUp + '=' +
                         ExtractFileName(FCurFile) + '(' + IntToStr(FCurLine) + ')')
      else
        FLabelPlaces.Add('|' + FirstUp + '=' +
                         ExtractFileName(FCurFile) + '(' + IntToStr(FCurLine) + ')');
    end;
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
    end
    // Однострочный IF, ELSE после ":" (IF c THEN a = 1 : b = "" ELSE
    // a = 2, Files.inc): ELSE заканчивает оператор THEN-части. FInlineIf
    // ставит ProcessIf первого оператора; ELSE в первом операторе
    // (IF c THEN a ELSE b) разбирает сам ProcessIf
    else if (Depth = 0) and FInlineIf and IsWord(Toks, TokIdx, 'ELSE') then
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

  // DECLARE ... LIB и CONST с числом или строкой - в начало программы
  HoistLine(Toks, FirstIdx, AText, AOut);
end;

// Строка - один оператор DECLARE ... LIB (параметры и результат - числа и
// строки) или CONST Имя = число / строка вне SUB, FUNCTION и TYPE: в
// первом проходе её перевод запоминается для начала программы
// (MainHeader), во втором на её месте - комментарий. Одно имя выносится
// один раз: повтор того же DECLARE или CONST в другом файле - тоже
// комментарий.
procedure TRqFbConv.HoistLine(const AToks: TToks; AFirstIdx: Integer;
                              const ASource: string; var AOut: string);
var
  KeyIdx, NameIdx, EqIdx, TokIdx, Depth, BreakPos, ValueCount: Integer;
  HoistKey, HoistText, KindUp: string;
  ProcRec: TRqProc;
begin
  if (FCurProc <> nil) or (FCurType <> nil) or FInType or FLineIsLabel then
    Exit;
  KeyIdx := AFirstIdx;
  if IsWord(AToks, KeyIdx, 'PRIVATE') or IsWord(AToks, KeyIdx, 'PUBLIC') then
    KeyIdx := NextSig(AToks, KeyIdx + 1, High(AToks));
  if (KeyIdx < 0) or (AToks[KeyIdx].Kind <> tkIdent) then
    Exit;
  // один оператор в строке
  Depth := 0;
  for TokIdx := KeyIdx to High(AToks) do
  begin
    if AToks[TokIdx].Kind = tkComment then
      Break;
    if IsOp(AToks, TokIdx, '(') then
      Inc(Depth)
    else if IsOp(AToks, TokIdx, ')') then
      Dec(Depth)
    else if (Depth = 0) and IsOp(AToks, TokIdx, ':') then
      Exit;
  end;

  if AToks[KeyIdx].Up = 'DECLARE' then
  begin
    TokIdx := NextSig(AToks, KeyIdx + 1, High(AToks));
    if TokIdx < 0 then
      Exit;
    KindUp := AToks[TokIdx].Up;
    if (KindUp <> 'SUB') and (KindUp <> 'FUNCTION') then
      Exit;
    NameIdx := NextSig(AToks, TokIdx + 1, High(AToks));
    if (NameIdx < 0) or (AToks[NameIdx].Kind <> tkIdent) or
       not IsWord(AToks, NextSig(AToks, NameIdx + 1, High(AToks)), 'LIB') then
      Exit;
    ProcRec := FindProc(AToks[NameIdx].Up);
    if (ProcRec = nil) or ProcRec.IsVariadic or
       (Pos('O', ProcRec.LibKinds) > 0) then
      Exit;
    if ProcRec.IsFunc and not ((ProcRec.RetType = 'STRING') or
                               IsNumericType(ProcRec.RetType)) then
      Exit;
    HoistKey := 'D|' + ProcRec.Name;
  end
  else if AToks[KeyIdx].Up = 'CONST' then
  begin
    NameIdx := NextSig(AToks, KeyIdx + 1, High(AToks));
    if (NameIdx < 0) or (AToks[NameIdx].Kind <> tkIdent) then
      Exit;
    EqIdx := NextSig(AToks, NameIdx + 1, High(AToks));
    if not IsOp(AToks, EqIdx, '=') then
      Exit;
    // значение - число или строка (знак перед числом можно)
    ValueCount := 0;
    for TokIdx := EqIdx + 1 to High(AToks) do
      case AToks[TokIdx].Kind of
        tkSpace:
          ;
        tkComment:
          Break;
        tkNumber, tkString:
          Inc(ValueCount);
        tkOp:
          if (AToks[TokIdx].Text <> '-') and (AToks[TokIdx].Text <> '+') then
            Exit;
      else
        Exit;
      end;
    if ValueCount <> 1 then
      Exit;
    HoistKey := 'C|' + AToks[NameIdx].Up;
  end
  else
    Exit;

  if FPass = 1 then
  begin
    if FHoistKeys.IndexOf(HoistKey) >= 0 then
      Exit;
    // перевод - первой физической строкой, без " _" продолжения
    HoistText := AOut;
    BreakPos := Pos(#10, HoistText);
    if BreakPos > 0 then
      HoistText := Copy(HoistText, 1, BreakPos - 1);
    HoistText := TrimRight(StringReplace(HoistText, #13, '', [rfReplaceAll]));
    if Copy(HoistText, Length(HoistText) - 1, 2) = ' _' then
      HoistText := TrimRight(Copy(HoistText, 1, Length(HoistText) - 2));
    FHoistKeys.Put(HoistKey, HoistText);
    // сообщения fbc об этой строке - с файлом и строкой исходника RapidQ
    HoistText := '#line ' + IntToStr(FCurLine - 1) + ' "' + FCurFile + '"' +
                 CrLf + HoistText;
    if HoistKey[1] = 'C' then
      FHoistConsts.Add(HoistText)
    else
      FHoistDecls.Add(HoistText);
  end
  else if FHoistKeys.IndexOf(HoistKey) >= 0 then
    AOut := CommentOut(ASource);
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
  ItemIdx := FAllMembers.IndexOf(AMemberUp);
  if ItemIdx < 0 then
    Result := #0
  else
    Result := FAllMembers.ValueAt(ItemIdx)[1];
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
  ArgIdx, CloseIdx, TokIdx: Integer;
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
      // $DEFINE имени, которое уже определено и не снято $UNDEF
      if FDefines.IndexOf(AToks[ArgIdx].Up) >= 0 then
        Suspect('$DEFINE ' + AToks[ArgIdx].Text + ' already defined - уже определён в ' +
                FDefinePlaces.Get(AToks[ArgIdx].Up) + ' как "' +
                FDefines.Get(AToks[ArgIdx].Up) + '"');
      FDefines.Put(AToks[ArgIdx].Up, Value);
      FDefinePlaces.Put(AToks[ArgIdx].Up, FCurFile + '(' + IntToStr(FCurLine) + ')');
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
        FDefines.Remove(AToks[TokIdx].Up);
        FDefinePlaces.Remove(AToks[TokIdx].Up);
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

// GOTO / GOSUB Метка: метка должна быть в той же процедуре (или вне
// процедур, если GOTO вне процедур). У FreeBASIC метка видна только внутри
// своей SUB/FUNCTION, и fbc сообщает "Undefined label" без номера строки
// (RQdebugger: goto w8file в двух процедурах, метка w8file: - в третьей,
// у них самих метка w81file:). Здесь - ошибка с местом GOTO и местом метки.
procedure TRqFbConv.CheckLabel(const AToks: TToks; AFirst, ATo: Integer);
var
  LabelIdx, PlaceIdx: Integer;
  LabelUp, Scope, Places: string;
begin
  if FPass <> 2 then
    Exit;
  LabelIdx := NextSig(AToks, AFirst + 1, ATo);
  if (LabelIdx < 0) or (AToks[LabelIdx].Kind <> tkIdent) then
    Exit;
  LabelUp := AToks[LabelIdx].Up;
  Scope := '';
  if FCurProc <> nil then
    Scope := FCurProc.Name;
  if FLabelPlaces.IndexOfName(Scope + '|' + LabelUp) >= 0 then
    Exit;
  Places := '';
  for PlaceIdx := 0 to FLabelPlaces.Count - 1 do
    if Copy(FLabelPlaces.Names[PlaceIdx], Pos('|', FLabelPlaces.Names[PlaceIdx]),
            MaxInt) = '|' + LabelUp then
    begin
      if Places <> '' then
        Places := Places + ', ';
      Places := Places + FLabelPlaces.ValueFromIndex[PlaceIdx];
      if Copy(FLabelPlaces.Names[PlaceIdx], 1, 1) <> '|' then
        Places := Places + ' в ' + Copy(FLabelPlaces.Names[PlaceIdx], 1,
                                        Pos('|', FLabelPlaces.Names[PlaceIdx]) - 1)
      else
        Places := Places + ' вне процедур';
    end;
  if Places <> '' then
    Error(AToks[AFirst].Text + ' ' + AToks[LabelIdx].Text + ': метка в другой ' +
          'процедуре (' + Places + ') - у FreeBASIC метка видна только в своей ' +
          'SUB/FUNCTION')
  else
    Error(AToks[AFirst].Text + ' ' + AToks[LabelIdx].Text + ': метки ' +
          AToks[LabelIdx].Text + ' нет');
end;

// Блоки вне SUB/FUNCTION: начало - +1, конец - -1 (FModBlocks). IF - только
// блочный (после THEN ничего); NEXT i, j закрывает два FOR
procedure TRqFbConv.TrackModBlock(const AToks: TToks; AFirst, ATo: Integer);
var
  Up: string;
  NextIdx, TokIdx, ThenIdx, Depth: Integer;
begin
  Up := AToks[AFirst].Up;
  NextIdx := NextSig(AToks, AFirst + 1, ATo);
  if (Up = 'WITH') or (Up = 'FOR') or (Up = 'DO') or (Up = 'WHILE') or
     (Up = 'SELECT') then
    Inc(FModBlocks)
  else if Up = 'IF' then
  begin
    ThenIdx := -1;
    Depth := 0;
    for TokIdx := AFirst + 1 to ATo do
      if IsOp(AToks, TokIdx, '(') then
        Inc(Depth)
      else if IsOp(AToks, TokIdx, ')') then
        Dec(Depth)
      else if (Depth = 0) and IsWord(AToks, TokIdx, 'THEN') then
      begin
        ThenIdx := TokIdx;
        Break;
      end;
    if (ThenIdx >= 0) and (NextSig(AToks, ThenIdx + 1, ATo) < 0) then
      Inc(FModBlocks);
  end
  else if (Up = 'END') and (IsWord(AToks, NextIdx, 'WITH') or
          IsWord(AToks, NextIdx, 'SELECT') or IsWord(AToks, NextIdx, 'IF')) then
    Dec(FModBlocks)
  else if (Up = 'LOOP') or (Up = 'WEND') then
    Dec(FModBlocks)
  else if Up = 'NEXT' then
  begin
    Dec(FModBlocks);
    for TokIdx := AFirst + 1 to ATo do
      if IsOp(AToks, TokIdx, ',') then
        Dec(FModBlocks);
  end;
  if FModBlocks < 0 then
    FModBlocks := 0;
end;

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
  if (FCurProc = nil) and (AToks[FirstIdx].Kind = tkIdent) then
    TrackModBlock(AToks, FirstIdx, ATo);
  if IsOp(AToks, FirstIdx, '?') then
  begin
    ProcessPrint(AToks, FirstIdx, ATo);
    Exit;
  end;
  // .Свойство = x внутри WITH Объект - как Объект.Свойство = x;
  // .Свойство++ (QFILEDIALOG.INC: .SelCount++) - как Перем ++
  if IsOp(AToks, FirstIdx, '.') then
  begin
    if not ProcessPlusPlus(AToks, FirstIdx, ATo) then
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

  // EXIT EVENT (rapidq2.inc, QDockForm: IF BTN = 1 THEN EXIT EVENT) -
  // обработчик события переводится в Sub
  if (Up = 'EXIT') and IsWord(AToks, NextIdx, 'EVENT') then
  begin
    AToks[NextIdx].OutText := 'Sub';
    Exit;
  end;

  // FOR, переведённый в WHILE (ProcessFor): EXIT FOR - Exit While, NEXT -
  // шаг и WEND
  if (Up = 'EXIT') and IsWord(AToks, NextIdx, 'FOR') and (FForCount > 0) and
     (FForTargets[FForCount - 1] <> '') then
  begin
    AToks[NextIdx].OutText := 'While';
    Exit;
  end;
  if (Up = 'NEXT') and (FindProc(Up) = nil) then
  begin
    ProcessNext(AToks, FirstIdx, ATo);
    Exit;
  end;

  // Перем ++; This.Член++ (в методе TYPE ... EXTENDS: QFILEDIALOG.INC
  // .SelCount++ внутри WITH This, RewriteTypeText делает из него
  // This.SelCount++)
  if (not InList(FKeywords, Up) or ((Up = 'THIS') and IsOp(AToks, NextIdx, '.'))) and
     ProcessPlusPlus(AToks, FirstIdx, ATo) then
    Exit;

  // SWAP со свойством объекта - через временную переменную
  if (Up = 'SWAP') and ProcessSwap(AToks, FirstIdx, ATo) then
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
    CheckLabel(AToks, FirstIdx, ATo)
  else if Up = 'GOSUB' then
  begin
    CheckLabel(AToks, FirstIdx, ATo);
    ProcessGosub(AToks, FirstIdx, ATo);
  end
  else if Up = 'RETURN' then
    ProcessReturn(AToks, FirstIdx, ATo)
  else if (Up = 'INC') or (Up = 'DEC') then
    ProcessIncDec(AToks, FirstIdx, ATo)
  else if (Up = 'BIND') and (FindProc(Up) = nil) then
    ProcessBind(AToks, FirstIdx, ATo)
  else if (Up = 'CALLFUNC') and (FindProc(Up) = nil) and
          ((FCurType = nil) or (FTypeBody = 0)) then
    ProcessCallFuncStmt(AToks, FirstIdx, ATo)
  else if (Up = 'QUICKSORT') and (FindProc(Up) = nil) then
    ProcessQuickSort(AToks, FirstIdx, ATo)
  else if (Up = 'INITARRAY') and (FindProc(Up) = nil) then
    ProcessInitArray(AToks, FirstIdx, ATo)
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
  begin
    // оператор RapidQ (SELECT CASE, DO, LOOP, NEXT, WHILE, RETURN...):
    // дальше - выражения. Оператор из rqrt.bi (SENDMESSAGE h, m, w, l;
    // SHELL "команда") - под своим именем там
    if FFuncMap.IndexOf(Up) >= 0 then
    begin
      AToks[FirstIdx].OutText := FFuncMap.Get(Up);
      MemRecordArgs(AToks, FirstIdx, ATo);
    end;
    ProcessExpr(AToks, FirstIdx + 1, ATo);
  end
  else
    ProcessAssignOrCall(AToks, FirstIdx, ATo);
end;

// Выражение: переменные переименовываются, необъявленные заводятся
procedure TRqFbConv.ProcessExpr(var AToks: TToks; AFrom, ATo: Integer);
var
  TokIdx, PrevIdx, OpenIdx, CloseIdx: Integer;
  LibProc: TRqProc;
begin
  // Унарный "+" (после знака, "(" или "," и в начале выражения) убирается:
  // у числа он ничего не меняет, у строки FreeBASIC его не принимает
  // (RQdebugger: sketchbookPathEdit.text++fname$-fext$+"")
  for TokIdx := AFrom to ATo do
    if IsOp(AToks, TokIdx, '+') then
    begin
      PrevIdx := PrevSig(AToks, TokIdx - 1);
      if ((PrevIdx < AFrom) or ((AToks[PrevIdx].Kind = tkOp) and
          (AToks[PrevIdx].Text <> ')') and (AToks[PrevIdx].Text <> ']'))) and
         (NextSig(AToks, TokIdx + 1, ATo) >= 0) then
      begin
        AToks[TokIdx].OutText := '';
        AToks[TokIdx].Kind := tkSpace;
      end;
    end;
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

  // Вызовы функций DLL со скобками: аргументы - к тому, что ждёт функция
  // (WrapLibArgs). После разбора всех слов: обёртки - снаружи того, что
  // разбор уже дописал к аргументам.
  for TokIdx := AFrom to ATo do
    if (AToks[TokIdx].Kind = tkIdent) and
       not IsOp(AToks, PrevSig(AToks, TokIdx - 1), '.') and
       (FindVar(AToks[TokIdx].Up) = nil) then
    begin
      LibProc := FindProc(AToks[TokIdx].Up);
      if (LibProc = nil) or (LibProc.LibKinds = '') then
        Continue;
      OpenIdx := NextSig(AToks, TokIdx + 1, ATo);
      if not IsOp(AToks, OpenIdx, '(') then
        Continue;
      CloseIdx := MatchParen(AToks, OpenIdx, ATo);
      if CloseIdx > OpenIdx + 1 then
        WrapLibArgs(AToks, OpenIdx + 1, CloseIdx - 1, LibProc);
    end;
end;

// Аргумент - сама строковая переменная (элемент массива, поле записи):
// у неё есть постоянный адрес символов
function TRqFbConv.IsStrVarRef(const AToks: TToks; AFrom, ATo: Integer): Boolean;
var
  TokIdx, FirstIdx, Depth: Integer;
begin
  Result := False;
  FirstIdx := NextSig(AToks, AFrom, ATo);
  if (FirstIdx < 0) or (AToks[FirstIdx].Kind <> tkIdent) or
     (FindVar(AToks[FirstIdx].Up) = nil) then
    Exit;
  Depth := 0;
  for TokIdx := FirstIdx to ATo do
  begin
    if IsOp(AToks, TokIdx, '(') then
      Inc(Depth)
    else if IsOp(AToks, TokIdx, ')') then
      Dec(Depth)
    else if (Depth = 0) and not (AToks[TokIdx].Kind in [tkIdent, tkSpace]) and
            not IsOp(AToks, TokIdx, '.') then
      Exit;
  end;
  Result := Depth = 0;
end;

// Аргументы вызова функции DLL (DECLARE ... LIB): что передать, решает
// объявление параметра, как у функции Windows:
//   параметр - число ByVal (LONG, адрес), а передана строка - адрес её
//     символов: переменная - RqVarPtr(@s), выражение - RqStrTmpAddr(...);
//   параметр STRING (ZString Ptr), а передано число (адрес, 0&) -
//     Cast(ZString Ptr, число);
//   параметр - число ByVal, а передана запись (TYPE без EXTENDS) -
//     Cast(Integer, @запись);
//   параметр - запись, объект или массив, а передано число (адрес, 0&) -
//     ByVal Cast(Any Ptr, число).
// Остальные аргументы - как есть.
procedure TRqFbConv.WrapLibArgs(var AToks: TToks; AFrom, ATo: Integer;
                                AProc: TRqProc);
var
  TokIdx, ArgStart, ArgEnd, ArgNo, FirstIdx, LastIdx, Depth: Integer;
  ParamKind: Char;
begin
  ArgStart := AFrom;
  ArgNo := 0;
  while ArgStart <= ATo do
  begin
    ArgEnd := ATo;
    Depth := 0;
    for TokIdx := ArgStart to ATo do
    begin
      if IsOp(AToks, TokIdx, '(') then
        Inc(Depth)
      else if IsOp(AToks, TokIdx, ')') then
        Dec(Depth)
      else if (Depth = 0) and IsOp(AToks, TokIdx, ',') then
      begin
        ArgEnd := TokIdx - 1;
        Break;
      end;
    end;
    Inc(ArgNo);
    if ArgNo > Length(AProc.LibKinds) then
      Exit;
    ParamKind := AProc.LibKinds[ArgNo];
    FirstIdx := NextSig(AToks, ArgStart, ArgEnd);
    LastIdx := PrevSig(AToks, ArgEnd);
    if (FirstIdx >= 0) and (LastIdx >= FirstIdx) and
       not IsWord(AToks, FirstIdx, 'BYVAL') then
    begin
      // Запись (TYPE без EXTENDS) в параметр-число: адрес записи, как в
      // MEMCPY (MemRecordArgs). ConvertToTruePath.inc: SHGetFileInfo(...,
      // SFI, SizeOf(SFI), ...) при ByVal psfi As Long - функция заполняет
      // SFI, программа читает SFI.szDisplayName
      if (ParamKind = 'N') and ArgIsRecord(AToks, FirstIdx, LastIdx) then
      begin
        AToks[FirstIdx].Pre := 'Cast(Integer, @' + AToks[FirstIdx].Pre;
        AToks[LastIdx].Post := AToks[LastIdx].Post + ')';
      end
      else if (ParamKind = 'N') and ExprIsString(AToks, FirstIdx, LastIdx) then
      begin
        if IsStrVarRef(AToks, FirstIdx, LastIdx) then
          AToks[FirstIdx].Pre := 'RqVarPtr(@' + AToks[FirstIdx].Pre
        else
          AToks[FirstIdx].Pre := 'RqStrTmpAddr(' + AToks[FirstIdx].Pre;
        AToks[LastIdx].Post := AToks[LastIdx].Post + ')';
      end
      else if (ParamKind = 'S') and ExprIsNumber(AToks, FirstIdx, LastIdx) then
      begin
        AToks[FirstIdx].Pre := 'Cast(ZString Ptr, ' + AToks[FirstIdx].Pre;
        AToks[LastIdx].Post := AToks[LastIdx].Post + ')';
      end
      // Параметр-запись (ByRef ... AS OVERLAPPED), а передано число - это
      // адрес (0& - NULL, "не используется"): COMPORT.CMP, WriteFile(...,
      // 0&). В FreeBASIC адрес в параметр ByRef передаётся через ByVal
      else if (ParamKind = 'O') and ExprIsNumber(AToks, FirstIdx, LastIdx) then
      begin
        AToks[FirstIdx].Pre := 'ByVal Cast(Any Ptr, ' + AToks[FirstIdx].Pre;
        AToks[LastIdx].Post := AToks[LastIdx].Post + ')';
      end;
    end
    // То же с BYVAL в вызове: CreateFile(..., ByVal 0&, ...) в RQdebugger.
    // В 32 бит fbc принимает "ByVal 0&" как адрес, в 64 бит - нет (error
    // 58: LONG не адрес): ByVal Cast(Any Ptr, 0&)
    else if (FirstIdx >= 0) and IsWord(AToks, FirstIdx, 'BYVAL') and
            (NextSig(AToks, FirstIdx + 1, LastIdx) >= 0) and
            ExprIsNumber(AToks, NextSig(AToks, FirstIdx + 1, LastIdx), LastIdx) then
    begin
      if ParamKind = 'O' then
      begin
        AToks[NextSig(AToks, FirstIdx + 1, LastIdx)].Pre := 'Cast(Any Ptr, ' +
          AToks[NextSig(AToks, FirstIdx + 1, LastIdx)].Pre;
        AToks[LastIdx].Post := AToks[LastIdx].Post + ')';
      end
      else if ParamKind = 'S' then
      begin
        AToks[FirstIdx].OutText := '';
        AToks[NextSig(AToks, FirstIdx + 1, LastIdx)].Pre := 'Cast(ZString Ptr, ' +
          AToks[NextSig(AToks, FirstIdx + 1, LastIdx)].Pre;
        AToks[LastIdx].Post := AToks[LastIdx].Post + ')';
      end;
    end;
    ArgStart := ArgEnd + 2;
  end;
end;

// Объект.Свойство[N] (RQdebugger: TplPathEdit.text[len(TplPathEdit.text)])
// - символ строки, как s$[N] у переменной (WrapStrIndex): RqStrIdx(
// Объект.Свойство, N). Только простая форма Владелец.Свойство со
// строковым свойством (MemberIsString)
procedure TRqFbConv.WrapMemberStrIndex(var AToks: TToks; AIdx, ATo: Integer);
var
  OpenIdx, CloseIdx, DotIdx, OwnerIdx, InsPos: Integer;
  PreText: string;
begin
  OpenIdx := NextSig(AToks, AIdx + 1, ATo);
  if not IsOp(AToks, OpenIdx, '[') then
    Exit;
  CloseIdx := MatchBracket(AToks, OpenIdx, ATo);
  if CloseIdx < 0 then
    Exit;
  DotIdx := PrevSig(AToks, AIdx - 1);
  OwnerIdx := PrevSig(AToks, DotIdx - 1);
  if (OwnerIdx < 0) or (AToks[OwnerIdx].Kind <> tkIdent) or
     IsOp(AToks, PrevSig(AToks, OwnerIdx - 1), '.') or
     not MemberIsString(AToks, AIdx) then
    Exit;
  PreText := AToks[OwnerIdx].Pre;
  InsPos := 1;
  while Copy(PreText, InsPos, 9) = 'RqStrSub(' do
    Inc(InsPos, 9);
  Insert('RqStrIdx(', PreText, InsPos);
  AToks[OwnerIdx].Pre := PreText;
  AToks[OpenIdx].OutText := ', ';
  AToks[CloseIdx].OutText := ')';
end;

// Текст RapidQ из нескольких операторов через ":" - перевод (для
// операторов, которые переписываются через другие: ProcessSwap)
function TRqFbConv.TranslateFragment(const AText: string): string;
var
  Toks: TToks;
  TokIdx, StartIdx, Depth: Integer;
  SavedInlineIf, SavedLabel: Boolean;
  SavedLost: Integer;
begin
  SavedInlineIf := FInlineIf;
  SavedLabel := FLineIsLabel;
  SavedLost := FLostLines;
  try
    FInlineIf := False;
    FLostLines := 0;
    Lex(AText, Toks);
    StartIdx := 0;
    Depth := 0;
    for TokIdx := 0 to High(Toks) do
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
    if StartIdx <= High(Toks) then
      ProcessStatement(Toks, StartIdx, High(Toks));
    Result := '';
    for TokIdx := 0 to High(Toks) do
      Result := Result + Toks[TokIdx].Pre + Toks[TokIdx].OutText + Toks[TokIdx].Post;
  finally
    FInlineIf := SavedInlineIf;
    FLineIsLabel := SavedLabel;
    FLostLines := SavedLost;
  end;
end;

// SWAP a, b, где a или b - свойство объекта (RQdebugger: SWAP
// LangGrid1.cell(c, r), LangGrid1.cell(3, r)). Swap FreeBASIC меняет
// только переменные; свойство - через временную переменную и три
// присваивания, каждое переводится как обычно (Grid.Cell(c, r) = x ->
// SetCell). False - не тот случай, SWAP остаётся как есть.
function TRqFbConv.ProcessSwap(var AToks: TToks; AFirst, ATo: Integer): Boolean;
var
  TokIdx, CommaIdx, Depth, OpenIdx, CloseIdx: Integer;
  LeftText, RightText, TempName: string;

  // В операнде есть "." на верхнем уровне и владелец - объект
  function IsProp(AFrom, AUntil: Integer): Boolean;
  var
    FirstIdx, ScanIdx, ScanDepth: Integer;
    VarRec: TRqVar;
    OwnerType: string;
  begin
    Result := False;
    FirstIdx := NextSig(AToks, AFrom, AUntil);
    if (FirstIdx < 0) or (AToks[FirstIdx].Kind <> tkIdent) then
      Exit;
    if AToks[FirstIdx].Up = 'THIS' then
      OwnerType := 'THIS'
    else
    begin
      VarRec := FindVar(AToks[FirstIdx].Up);
      if VarRec = nil then
        Exit;
      OwnerType := UpperCase(VarRec.RqType);
      if not (InList(FObjClasses, OwnerType) or (FindTypeInfo(OwnerType) <> nil)) then
        Exit;
    end;
    ScanDepth := 0;
    for ScanIdx := FirstIdx to AUntil do
      if IsOp(AToks, ScanIdx, '(') then
        Inc(ScanDepth)
      else if IsOp(AToks, ScanIdx, ')') then
        Dec(ScanDepth)
      else if (ScanDepth = 0) and IsOp(AToks, ScanIdx, '.') then
      begin
        Result := True;
        Exit;
      end;
  end;

begin
  Result := False;
  // SWAP (a, b) - оба операнда в одних скобках (rapidq2.inc, QListViewEx:
  // swap (This.item(lx).caption, ...)); в документации - SWAP a, b.
  // Скобки становятся пробелами, дальше - как без них.
  OpenIdx := NextSig(AToks, AFirst + 1, ATo);
  CloseIdx := PrevSig(AToks, ATo);
  if IsOp(AToks, OpenIdx, '(') and (CloseIdx > OpenIdx) and
     (MatchParen(AToks, OpenIdx, ATo) = CloseIdx) then
  begin
    Depth := 0;
    for TokIdx := OpenIdx + 1 to CloseIdx - 1 do
      if IsOp(AToks, TokIdx, '(') then
        Inc(Depth)
      else if IsOp(AToks, TokIdx, ')') then
        Dec(Depth)
      else if (Depth = 0) and IsOp(AToks, TokIdx, ',') then
      begin
        for Depth := 0 to 1 do
        begin
          if Depth = 0 then
            CommaIdx := OpenIdx
          else
            CommaIdx := CloseIdx;
          AToks[CommaIdx].Kind := tkSpace;
          AToks[CommaIdx].Text := ' ';
          AToks[CommaIdx].Up := ' ';
          AToks[CommaIdx].OutText := ' ';
        end;
        Break;
      end;
  end;
  CommaIdx := -1;
  Depth := 0;
  for TokIdx := AFirst + 1 to ATo do
    if IsOp(AToks, TokIdx, '(') then
      Inc(Depth)
    else if IsOp(AToks, TokIdx, ')') then
      Dec(Depth)
    else if (Depth = 0) and IsOp(AToks, TokIdx, ',') then
    begin
      CommaIdx := TokIdx;
      Break;
    end;
  if CommaIdx < 0 then
    Exit;
  if not IsProp(AFirst + 1, CommaIdx - 1) and not IsProp(CommaIdx + 1, ATo) then
    Exit;
  LeftText := Trim(RawText(AToks, AFirst + 1, CommaIdx - 1));
  RightText := Trim(RawText(AToks, CommaIdx + 1, ATo));
  if ExprIsString(AToks, AFirst + 1, CommaIdx - 1) or
     ExprIsString(AToks, CommaIdx + 1, ATo) then
    TempName := 'rq_swap$'
  else
    TempName := 'rq_swap#';
  Rebuild(AToks, AFirst, ATo, TranslateFragment(
    TempName + ' = ' + LeftText + ' : ' + LeftText + ' = ' + RightText +
    ' : ' + RightText + ' = ' + TempName));
  Result := True;
end;

// Имя.Свойство, где Имя не объявлено ни переменной, ни объектом: одна
// неявная переменная Имя_Свойство (см. ProcessIdent). Только простая
// форма: за свойством не "(" и не ".", свойство - не метод и не событие
// ни одного класса. True - токены переписаны.
function TRqFbConv.DottedImplicit(var AToks: TToks; AIdx, ADotIdx,
  ATo: Integer): Boolean;
var
  MemberIdx, AfterIdx: Integer;
  DotName, MemberUp, RqType, Scope, DefaultText, SrcText: string;
  VarRec: TRqVar;
begin
  Result := False;
  MemberIdx := NextSig(AToks, ADotIdx + 1, ATo);
  if (MemberIdx < 0) or (AToks[MemberIdx].Kind <> tkIdent) then
    Exit;
  AfterIdx := NextSig(AToks, MemberIdx + 1, ATo);
  if IsOp(AToks, AfterIdx, '(') or IsOp(AToks, AfterIdx, '.') then
    Exit;
  MemberUp := AToks[MemberIdx].Up;
  // Метод или событие (MainForm.Show, X.OnClick = ...) - это обращение к
  // объекту, переменной оно быть не может: как раньше, ошибкой fbc
  if AnyMemberKind(MemberUp) in ['M', 'E'] then
    Exit;
  if SuffixOf(MemberUp) <> '' then
    RqType := SuffixType(SuffixOf(MemberUp))
  else if Pos(' ' + MemberUp + ' ', ' ' + RqStrPropText + ' ') > 0 then
    RqType := 'STRING'
  else
    RqType := SuffixType('');
  SrcText := AToks[AIdx].Text + '.' + AToks[MemberIdx].Text;
  DotName := BaseOf(AToks[AIdx].Text) + '_' + AToks[MemberIdx].Text;

  VarRec := FindVar(UpperCase(DotName));
  if VarRec = nil then
  begin
    Scope := '';
    if FCurProc <> nil then
      Scope := FCurProc.Name;
    VarRec := DeclareVar(DotName, RqType, Scope, False, False, False);
    VarRec.DotBase := AToks[AIdx].Up;
  end;
  if (FPass = 2) and FTypeCheck and not VarRec.Explicit then
    Error(AToks[AIdx].Text + ': переменная не объявлена ($TYPECHECK ON)');

  AToks[AIdx].OutText := VarRec.FbName;
  if (VarRec.Scope = '') and VarRec.Explicit then
    GlobalQualify(AToks, AIdx);
  // Точку и свойство - из вывода и из разбора: дальше по строке они
  // не идентификатор и не оператор
  ClearRange(AToks, ADotIdx, MemberIdx);
  AToks[ADotIdx].Kind := tkSpace;
  AToks[MemberIdx].Kind := tkSpace;
  AToks[AIdx].Text := DotName;
  AToks[AIdx].Up := UpperCase(DotName);

  if FPass = 2 then
  begin
    DefaultText := DefaultValueText(VarRec.RqType);
    SuspectOnce('DI|' + VarRec.Scope + '|' + VarRec.Name,
      SrcText + ': ' + Copy(SrcText, 1, Pos('.', SrcText) - 1) + ' не объявлен - ' +
      'переведено как неявная переменная ' + VarRec.FbName + ' (' +
      DefaultText + ', если ей нигде не присваивается)');
  end;
  Result := True;
end;

procedure TRqFbConv.ProcessIdent(var AToks: TToks; AIdx, ATo: Integer);
var
  Up: string;
  PrevIdx, NextIdx, TypeIdx, CloseIdx: Integer;
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
    else if FMemberMap.IndexOf(Up) >= 0 then
      AToks[AIdx].OutText := FMemberMap.Get(Up);
    // Объект.Свойство[N] - символ строки-свойства
    WrapMemberStrIndex(AToks, AIdx, ATo);
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
  // RESULT в выражении функции: значение функции FreeBASIC прочитать
  // нельзя (Function = только запись), поэтому функция, которая читает
  // RESULT, ведёт его в локальной rq_result (объявление - в заголовке,
  // LocalsText; запись - rq_result = ... : Function = rq_result,
  // ProcessAssignOrCall). Признак собирается в первом проходе.
  // (неявная переменная result вне FUNCTION - не помеха: она в модуле)
  if (Up = 'RESULT') and (FCurProc <> nil) and FCurProc.IsFunc and
     ((FindVar(Up) = nil) or not FindVar(Up).Explicit) then
  begin
    FCurProc.ResultRead := True;
    AToks[AIdx].OutText := 'rq_result';
    Exit;
  end;
  // RESULT вне FUNCTION (в SUB или в модуле: RQdebugger, result =
  // SendMessageApi(...)) - значения функции нет, это обычная неявная
  // переменная (слово RapidQ, но FreeBASIC о нём не знает)
  if (Up = 'RESULT') and not ((FCurProc <> nil) and FCurProc.IsFunc) then
  begin
    VarRec := ResolveVar(AToks[AIdx].Text, False);
    AToks[AIdx].OutText := VarRec.FbName;
    if (VarRec.Scope = '') and VarRec.Explicit then
      GlobalQualify(AToks, AIdx);
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
      SuspectOnce('TF|' + Up, AToks[AIdx].Text + ': не определено (нет $INCLUDE ' +
        '"RAPIDQ.INC" или CONST) - в RapidQ это необъявленная переменная, 0')
    else if (VarRec.Scope = '') then
      GlobalQualify(AToks, AIdx);
    Exit;
  end;
  // ASCEND / DESCEND - направление QUICKSORT, слова RapidQ (ни в одном
  // include не объявлены): 0 и 1 для RqQuickSort. Своя переменная или
  // CONST с таким именем - как есть
  if ((Up = 'ASCEND') or (Up = 'DESCEND')) and (FindProc(Up) = nil) then
  begin
    VarRec := FindVar(Up);
    if (VarRec = nil) or not VarRec.Explicit then
    begin
      if Up = 'ASCEND' then
        AToks[AIdx].OutText := '0'
      else
        AToks[AIdx].OutText := '1';
      Exit;
    end;
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
    // CODEPTR(This.Метод) / CODEPTR(Тип.Метод) в методе своего компонента
    // (QColorDialog.inc: CODEPTR(QCOLORDIALOG.HookProc)) -> адрес
    // переходника: обычной процедуры с параметрами метода, которая вызывает
    // метод у объекта, запомненного при взятии адреса (CodePtrMethod)
    if CodePtrMethod(AToks, AIdx, NextIdx, MatchParen(AToks, NextIdx, ATo)) then
      Exit;
    ProcRec := nil;
    if NextSig(AToks, NextIdx + 1, ATo) >= 0 then
      ProcRec := FindProc(AToks[NextSig(AToks, NextIdx + 1, ATo)].Up);
    if (ProcRec = nil) or
       (NextSig(AToks, NextSig(AToks, NextIdx + 1, ATo) + 1, ATo) <>
        MatchParen(AToks, NextIdx, ATo)) then
      Error(AToks[AIdx].Text + RawText(AToks, NextIdx, MatchParen(AToks, NextIdx, ATo)) +
            ': ожидалось имя SUB или FUNCTION (метод своего компонента - ' +
            'только внутри его TYPE: This.Метод или Тип.Метод)')
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
    ProcRec.Used := True;
    AToks[AIdx].OutText := ProcRec.FbName;
    GlobalQualify(AToks, AIdx);
    // Функция своей DLL - указатель: без скобок это был бы адрес, а не
    // вызов (x = GetVer у RapidQ - вызов)
    if ProcRec.DynLib and not IsOp(AToks, NextIdx, '(') and
       not IsOp(AToks, PrevSig(AToks, AIdx - 1), '@') then
      AToks[AIdx].Post := AToks[AIdx].Post + '()';
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
  // SIZEOF(INTEGER) и другие типы RapidQ - тип FreeBASIC: INTEGER у
  // RapidQ - 4 байта, Integer FreeBASIC в 64 бит - 8; WORD и DWORD в
  // FreeBASIC нет
  if (Up = 'SIZEOF') and IsOp(AToks, NextIdx, '(') then
  begin
    TypeIdx := NextSig(AToks, NextIdx + 1, ATo);
    if (TypeIdx >= 0) and (AToks[TypeIdx].Kind = tkIdent) and
       IsOp(AToks, NextSig(AToks, TypeIdx + 1, ATo), ')') and
       (FindVar(AToks[TypeIdx].Up) = nil) and
       IsNumericType(NormType(AToks[TypeIdx].Up)) then
      AToks[TypeIdx].OutText := FbType(NormType(AToks[TypeIdx].Up));
  end;
  // FORMAT$(формат, a, b, ...) -> RqFormat(формат, RqPList().Arg(a).Arg(b)):
  // значения разных типов по порядку (rqrt.bi)
  if (Up = 'FORMAT$') and (FindProc(Up) = nil) and IsOp(AToks, NextIdx, '(') and
     (MatchParen(AToks, NextIdx, ATo) > 0) then
  begin
    AToks[AIdx].OutText := 'RqFormat';
    TypeIdx := TopComma(AToks, NextIdx + 1, MatchParen(AToks, NextIdx, ATo) - 1);
    if TypeIdx > 0 then
      WrapVariadicArgs(AToks, TypeIdx + 1, MatchParen(AToks, NextIdx, ATo) - 1,
                       AIdx, True);
    Exit;
  end;
  // MEMCPY(Запись, ...) - адрес записи (см. MemRecordArgs)
  if (FFuncMap.IndexOf(Up) >= 0) and IsOp(AToks, NextIdx, '(') then
    MemRecordArgs(AToks, AIdx, ATo);
  // INTEGER(x) - значение x без изменений. Тест пользователя в RapidQ
  // 2026-10-10 (tests/research/IntCast.bas): INTEGER(2.7) -> 2.7,
  // INTEGER(-2.7) -> -2.7, INTEGER(2.5) -> 2.5. В rapidq2.inc:
  // integer((a - b) / 2), integer(powr.BatteryFlag)
  if (Up = 'INTEGER') and (FindProc(Up) = nil) and IsOp(AToks, NextIdx, '(') and
     not IsWord(AToks, PrevSig(AToks, AIdx - 1), 'AS') then
  begin
    AToks[AIdx].OutText := '';
    Exit;
  end;
  // ABS(Запись) - адрес записи, LONG: rapidq2.inc - "$DEFINE UDTPTR ABS" с
  // комментарием "Return the pointer of user defined type in a long value"
  // (QPageSetup: PSD.hDevMode = UDTPTR(DevM)). Только 32 бит
  if (Up = 'ABS') and (FindProc(Up) = nil) and IsOp(AToks, NextIdx, '(') then
  begin
    CloseIdx := MatchParen(AToks, NextIdx, ATo);
    if (CloseIdx > 0) and ArgIsRecord(AToks, NextIdx + 1, CloseIdx - 1) then
    begin
      AToks[AIdx].OutText := 'Cast';
      AToks[NextIdx].Post := AToks[NextIdx].Post + 'Long, Cast(Integer, @';
      AToks[CloseIdx].Pre := ')' + AToks[CloseIdx].Pre;
      Exit;
    end;
  end;
  // VARPTR(x) -> RqVarPtr(@x): у строки - адрес символов (StrPtr), у
  // остального - адрес; перегрузку выбирает fbc по типу указателя (rqrt.bi)
  if (Up = 'VARPTR') and IsOp(AToks, NextIdx, '(') and
     (MatchParen(AToks, NextIdx, ATo) > 0) then
  begin
    AToks[AIdx].OutText := 'RqVarPtr';
    AToks[NextIdx].Post := AToks[NextIdx].Post + '@';
    Exit;
  end;
  if FFuncMap.IndexOf(Up) >= 0 then
  begin
    AToks[AIdx].OutText := FFuncMap.Get(Up);
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
  // Необъявленное.Свойство (constants.inc: Val(StartIndent.Text), а
  // StartIndent нигде не объявлен) - одна неявная переменная
  // Имя_Свойство: строковая, если свойство во всех классах STRING
  // (RqStrPropText) или у него суффикс $, иначе по суффиксу. Без этого
  // имя заводилось числом, и fbc на StartIndent.Text давал error 265.
  if ((VarRec = nil) or not VarRec.Explicit) and IsOp(AToks, NextIdx, '.') then
  begin
    if DottedImplicit(AToks, AIdx, NextIdx, ATo) then
      Exit;
    // Метод или свойство со скобками у необъявленного имени (RQdebugger:
    // FileListBox.Item(ixx), MainForm.Show - объектов нет). Перевести не
    // во что: что RapidQ даёт для них, не известно; вместо непонятной
    // ошибки fbc - своя, с именем
    if (FPass = 2) and (NextSig(AToks, NextIdx + 1, ATo) >= 0) and
       (AToks[NextSig(AToks, NextIdx + 1, ATo)].Kind = tkIdent) then
      // по разу на строку: одно имя в строке встречается и дважды
      ErrorOnce('UO|' + AToks[AIdx].Up + '|' + FCurFile + '|' + IntToStr(FCurLine),
        AToks[AIdx].Text + '.' +
        AToks[NextSig(AToks, NextIdx + 1, ATo)].Text + ': ' + AToks[AIdx].Text +
        ' не объявлен - ни переменной, ни объектом (DIM, CREATE)');
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
    SuspectOnce('NA|' + VarRec.Scope + '|' + VarRec.Name, AToks[AIdx].Text +
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
  ResultCopy: Boolean;
begin
  ResultCopy := False;
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
        ProcRec.Used := True;
        AToks[FirstIdx].OutText := ProcRec.FbName;
        GlobalQualify(AToks, FirstIdx);
      end
      // процедура RapidQ из rqrt.bi (EXTRACTRESOURCE)
      else if FFuncMap.IndexOf(AToks[FirstIdx].Up) >= 0 then
      begin
        AToks[FirstIdx].OutText := FFuncMap.Get(AToks[FirstIdx].Up);
        MemRecordArgs(AToks, FirstIdx, ATo);
      end;
      ProcessExpr(AToks, FirstIdx + 1, ATo);
      // Вызов процедуры DLL оператором: Имя a, b или Имя(a, b)
      if (ProcRec <> nil) and (ProcRec.LibKinds <> '') then
      begin
        TokIdx := NextSig(AToks, FirstIdx + 1, ATo);
        if IsOp(AToks, TokIdx, '(') and (MatchParen(AToks, TokIdx, ATo) = PrevSig(AToks, ATo)) then
        begin
          if MatchParen(AToks, TokIdx, ATo) > TokIdx + 1 then
            WrapLibArgs(AToks, TokIdx + 1, MatchParen(AToks, TokIdx, ATo) - 1, ProcRec);
        end
        else if TokIdx >= 0 then
          WrapLibArgs(AToks, FirstIdx + 1, ATo, ProcRec);
      end;
      // Своя DLL - вызов через указатель, аргументы - в скобках
      if (ProcRec <> nil) and ProcRec.DynLib then
      begin
        TokIdx := NextSig(AToks, FirstIdx + 1, ATo);
        if TokIdx < 0 then
          AToks[FirstIdx].Post := AToks[FirstIdx].Post + '()'
        else if not (IsOp(AToks, TokIdx, '(') and
                     (MatchParen(AToks, TokIdx, ATo) = PrevSig(AToks, ATo))) then
        begin
          AToks[FirstIdx].Post := AToks[FirstIdx].Post + '(';
          AToks[PrevSig(AToks, ATo)].Post := AToks[PrevSig(AToks, ATo)].Post + ')';
        end;
      end;
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

  // Число = Объект.Icon (rapidq2.inc, QFormEx.AddTrayIcon: .TrayIcon.hIcon
  // = QForm.Icon) - 0. Icon в RapidQ только для записи (документация,
  // qform.html: Icon STRING, W); тест пользователя 2026-10-10: H = F.Icon
  // даёт 0, S = F.Icon - "". В RqLcl Icon - строка, и присваивание числу
  // fbc отвергал (error 181).
  if (RhsLast > RhsFirst) and (AToks[RhsLast].Kind = tkIdent) and
     (AToks[RhsLast].Up = 'ICON') and
     IsOp(AToks, PrevSig(AToks, RhsLast - 1), '.') and
     not ExprIsString(AToks, FirstIdx, EqIdx - 1) then
  begin
    TokIdx := RhsFirst;
    while (TokIdx >= 0) and (TokIdx < RhsLast) and
          ((AToks[TokIdx].Kind = tkIdent) or IsOp(AToks, TokIdx, '.')) do
      TokIdx := NextSig(AToks, TokIdx + 1, RhsLast);
    if TokIdx = RhsLast then
    begin
      for TokIdx := RhsFirst + 1 to RhsLast do
      begin
        AToks[TokIdx].Kind := tkSpace;
        AToks[TokIdx].Text := '';
        AToks[TokIdx].Up := '';
        AToks[TokIdx].OutText := '';
      end;
      AToks[RhsFirst].Kind := tkNumber;
      AToks[RhsFirst].Text := '0';
      AToks[RhsFirst].Up := '0';
      AToks[RhsFirst].OutText := '0';
      RhsLast := RhsFirst;
    end;
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
        ProcRec.Used := True;
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
    if FCurProc.ResultRead then
    begin
      // функция читает RESULT - значение в rq_result, копия в Function
      AToks[FirstIdx].OutText := 'rq_result';
      ResultCopy := True;
    end
    else if (Up = 'RESULT') or (FCurType <> nil) then
      AToks[FirstIdx].OutText := 'Function'
    else
      AToks[FirstIdx].OutText := FCurProc.FbName;
    TargetType := FCurProc.RetType;
  end
  else if InList(FKeywords, Up) and (FindVar(Up) = nil) and
          not ((Up = 'RESULT') and (LhsEnd < 0)) then
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
  begin
    if ResultCopy then
      AToks[RhsLast].Post := AToks[RhsLast].Post + ' : Function = rq_result';
    Exit;
  end;
  if IsNumericType(TargetType) and ExprIsString(AToks, RhsFirst, RhsLast) then
    Suspect(Display + ' = ' + RawText(AToks, RhsFirst, RhsLast) +
         ': строка в числовую переменную - будет 0');
  if (TargetType = 'STRING') and ExprIsNumber(AToks, RhsFirst, RhsLast) then
    Suspect(Display + ' = ' + RawText(AToks, RhsFirst, RhsLast) +
         ': число в строковую переменную - будет пустая строка');
  AToks[RhsFirst].Pre := Conv + '(' + AToks[RhsFirst].Pre;
  AToks[RhsLast].Post := AToks[RhsLast].Post + ', "' +
                         StringReplace(Display, '"', '', [rfReplaceAll]) +
                         '", __FILE__, __LINE__)';
  if ResultCopy then
    AToks[RhsLast].Post := AToks[RhsLast].Post + ' : Function = rq_result';
end;

// DIM / REDIM: имя[суффикс] [(размеры)] [AS тип], ...
procedure TRqFbConv.ProcessDim(var AToks: TToks; AFrom, ATo: Integer);
var
  TokIdx, NameIdx, OpenIdx, CloseIdx, AsIdx, TypeIdx, ItemEnd, Depth: Integer;
  IsRedim, Preserve, IsArray, Dynamic: Boolean;
  Items, Extra, Scope, RqType, StarLen, DimsText, ItemText, InitText: string;
  StaticItems: string;
  VarRec: TRqVar;
  HasOwnType: Boolean;
begin
  HasOwnType := False;
  IsRedim := AToks[AFrom].Up = 'REDIM';
  TokIdx := NextSig(AToks, AFrom + 1, ATo);
  Preserve := IsWord(AToks, TokIdx, 'PRESERVE');
  if Preserve then
    TokIdx := NextSig(AToks, TokIdx + 1, ATo);
  Scope := '';
  if FCurProc <> nil then
    Scope := FCurProc.Name;
  Items := '';
  StaticItems := '';
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
      // свой TYPE объявлен в программе - в начало файла его не перенести
      if InList(FTypes, RqType) then
        HasOwnType := True;
      if InList(FGuiClasses, RqType) then
        FHasGui := True;
      VarRec := DeclareVar(AToks[NameIdx].Text, RqType, Scope, IsArray, True,
                           False);
      NoteDef('V|' + DefScope(Scope) + '|' + VarRec.Name, AToks[NameIdx].Text);
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
    // Объект (класс RapidQ или свой компонент), объявленный DIM внутри
    // SUB/FUNCTION, у RapidQ создаётся один раз и хранит содержимое между
    // вызовами (тест пользователя 2026-10-09: QMemoryStream.Size на входе
    // 0, 4, 8, QStringList.ItemCount 0, 1, 2; адрес Mem.Pointer тот же) -
    // Static. Массив объектов - как раньше (у Static FreeBASIC границы
    // должны быть константами)
    if not IsRedim and (Scope <> '') and not IsArray and
       (InList(FObjClasses, RqType) or (FindTypeInfo(RqType) <> nil)) then
    begin
      if StaticItems <> '' then
        StaticItems := StaticItems + ', ';
      StaticItems := StaticItems + ItemText;
    end
    else
    begin
      if Items <> '' then
        Items := Items + ', ';
      Items := Items + ItemText;
    end;
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
  else if (Scope = '') and (FModBlocks > 0) and (Extra = '') and
          (Pos(' = ', Items) = 0) and not HasOwnType then
  begin
    // DIM внутри WITH, IF, FOR... вне SUB: в FreeBASIC Dim Shared внутри
    // блока нельзя (error 96, RQdebugger: DIM CheckFont AS QFONT внутри
    // WITH RQdbini). Переменная модуля - в начало главного файла, к
    // перенесённым DECLARE (тип - число, строка или класс RapidQ из
    // rqlcl.bi, он подключён раньше); на месте оператор убирается (в
    // строке могут быть и другие операторы через ":")
    if FPass = 1 then
      FHoistDecls.Add('#line ' + IntToStr(FCurLine - 1) + ' "' + FCurFile + '"' +
                      CrLf + 'Dim Shared ' + Items);
    Rebuild(AToks, AFrom, ATo, '');
  end
  else if Scope = '' then
    Rebuild(AToks, AFrom, ATo, 'Dim Shared ' + Items + Extra)
  else if StaticItems = '' then
    Rebuild(AToks, AFrom, ATo, 'Dim ' + Items + Extra)
  else if Items = '' then
    Rebuild(AToks, AFrom, ATo, 'Static ' + StaticItems + Extra)
  else
    Rebuild(AToks, AFrom, ATo, 'Static ' + StaticItems + ' : Dim ' + Items + Extra);
end;

// DEFINT a, b = 5, c(3) = {1,2,3,4} - объявление переменных
// Выражение - константа: числа, строки, знаки и имена CONST
function TRqFbConv.InitIsConst(const AToks: TToks; AFrom, ATo: Integer): Boolean;
var
  TokIdx: Integer;
  VarRec: TRqVar;
begin
  Result := False;
  for TokIdx := AFrom to ATo do
    if AToks[TokIdx].Kind = tkIdent then
    begin
      if (AToks[TokIdx].Up = 'AND') or (AToks[TokIdx].Up = 'OR') or
         (AToks[TokIdx].Up = 'XOR') or (AToks[TokIdx].Up = 'NOT') or
         (AToks[TokIdx].Up = 'MOD') or (AToks[TokIdx].Up = 'SHL') or
         (AToks[TokIdx].Up = 'SHR') then
        Continue;
      VarRec := FindVar(AToks[TokIdx].Up);
      if (VarRec = nil) or not VarRec.IsConst then
        Exit;
    end;
  Result := True;
end;

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
    NoteDef('V|' + DefScope(Scope) + '|' + VarRec.Name, AToks[NameIdx].Text);
    ItemText := VarRec.FbName + DimsText + ' As ' + FbType(RqType);
    // у FreeBASIC строку переменной длины нельзя инициализировать в Dim
    if (InitText <> '') and (RqType = 'STRING') and not IsArray then
      Extra := Extra + ' : ' + VarRec.FbName + InitText
    // DEFINT lpCallBack_4 = CODEPTR(MasterCallBack_4) (NewWndProc.Inc,
    // CallBack_N.Inc): адрес процедуры - Integer (размер указателя) и
    // присваивание отдельным оператором. "Dim Shared x As Long =
    // Cast(Integer, @Proc)" fbc 64 бит отвергает (error 11, Expected
    // constant): адрес в LONG не помещается
    else if (InitText <> '') and not IsArray and
            (IsWord(AToks, NextSig(AToks, TokIdx + 1, ItemEnd), 'CODEPTR') or
             IsWord(AToks, NextSig(AToks, TokIdx + 1, ItemEnd), 'CALLBACK')) then
    begin
      ItemText := VarRec.FbName + ' As Integer';
      Extra := Extra + ' : ' + VarRec.FbName + InitText;
    end
    // Вне процедур значение не константа (rapidq2.inc: DefInt
    // gRQ2_SND_OS_Version = gRQ2_GetVersion And 255): Dim Shared FreeBASIC
    // принимает только константу (error 11) - присваивание отдельно
    else if (InitText <> '') and not IsArray and (Scope = '') and
            not InitIsConst(AToks, TokIdx + 1, ItemEnd) then
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
  NoteDef('V|' + DefScope(Scope) + '|' + VarRec.Name, 'CONST ' + AToks[NameIdx].Text);
  AToks[NameIdx].OutText := VarRec.FbName;
  // Строка с нулевым символом (QFILEDIALOG.INC: CONST fdStrTerm$ =
  // CHR$(0) + CHR$(0)): константа FreeBASIC - строка с завершающим нулём,
  // нулевой символ в ней не помещается, fbc: error 11 "Expected constant".
  // Вместо неё - переменная с тем же значением, присваивание на месте
  // CONST
  if IsOp(AToks, EqIdx, '=') and (RqType = 'STRING') and
     HasChrZero(AToks, EqIdx + 1, ATo) then
  begin
    if Scope = '' then
      AToks[AFrom].OutText := 'Dim Shared'
    else
      AToks[AFrom].OutText := 'Dim';
    AToks[NameIdx].Post := AToks[NameIdx].Post + ' As String : ' + VarRec.FbName;
    WarnOnce('CZ|' + Scope + '|' + VarRec.Name, 'CONST ' + AToks[NameIdx].Text +
      ': в строке есть CHR$(0) - в FreeBASIC это переменная ' + VarRec.FbName);
  end;
  if EqIdx >= 0 then
    ProcessExpr(AToks, EqIdx + 1, ATo);
end;

// В выражении есть CHR$(0) / CHR(0) (ноль - числом: 0, 0&, &H0)
function TRqFbConv.HasChrZero(const AToks: TToks; AFrom, ATo: Integer): Boolean;
var
  TokIdx, OpenIdx, ArgIdx, CloseIdx: Integer;
  ArgText: string;
begin
  Result := False;
  for TokIdx := AFrom to ATo do
    if (AToks[TokIdx].Kind = tkIdent) and
       ((AToks[TokIdx].Up = 'CHR$') or (AToks[TokIdx].Up = 'CHR')) then
    begin
      OpenIdx := NextSig(AToks, TokIdx + 1, ATo);
      if not IsOp(AToks, OpenIdx, '(') then
        Continue;
      ArgIdx := NextSig(AToks, OpenIdx + 1, ATo);
      CloseIdx := NextSig(AToks, ArgIdx + 1, ATo);
      if (ArgIdx < 0) or (AToks[ArgIdx].Kind <> tkNumber) or
         not IsOp(AToks, CloseIdx, ')') then
        Continue;
      ArgText := UpperCase(AToks[ArgIdx].Text);
      while (ArgText <> '') and (ArgText[Length(ArgText)] in ['&', '%', '!', '#']) do
        Delete(ArgText, Length(ArgText), 1);
      if Copy(ArgText, 1, 2) = '&H' then
        ArgText := '$' + Copy(ArgText, 3, MaxInt);
      if StrToIntDef(ArgText, -1) = 0 then
      begin
        Result := True;
        Exit;
      end;
    end;
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
  FLibKinds := '';
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
      begin
        // STRING у функции DLL: RapidQ передаёт указатель на строку
        // (документация, глава 9), как ByVal As String у VB. В fbc 1.10
        // ByVal As String - сама строка (12 байт на стеке, CreateEventA@24
        // вместо @16 - проверено), поэтому ZString Ptr: String fbc
        // передаёт в него сам
        ItemText := 'ByVal ' + VarRec.FbName + ' As ZString Ptr';
      end
      else
      begin
        if ByRefFlag or ((FByRefDefault or IsObjectType(RqType)) and
                         not ByValFlag) then
          ItemText := 'ByRef '
        else
          ItemText := 'ByVal ';
        ItemText := ItemText + VarRec.FbName + ' As ' + FbType(RqType);
      end;
      // Вид параметра функции DLL - для вызовов (WrapLibArgs)
      if FLibParams then
      begin
        if IsArray then
          FLibKinds := FLibKinds + 'O'
        else if RqType = 'STRING' then
          FLibKinds := FLibKinds + 'S'
        else if not IsNumericType(RqType) then
          FLibKinds := FLibKinds + 'O'
        else if Copy(ItemText, 1, 6) = 'ByRef ' then
          FLibKinds := FLibKinds + 'R'
        else
          FLibKinds := FLibKinds + 'N';
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
  FCurProcPlace := FCurFile + '(' + IntToStr(FCurLine) + ')';
  NoteDef('P||' + ProcRec.Name, Up + ' ' + AToks[NameIdx].Text);
  ProcRec.IsFunc := (Up = 'FUNCTION') or (Up = 'FUNCTIONI');
  ProcRec.IsVariadic := (Up = 'SUBI') or (Up = 'FUNCTIONI');
  FCurProc := ProcRec;
  FCurProcPlace := FCurFile + '(' + IntToStr(FCurLine) + ')';
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
  // Функция читает RESULT - его локальная копия (ProcessIdent)
  if (FPass = 2) and ProcRec.IsFunc and ProcRec.ResultRead then
    Locals := Locals + ' : Dim rq_result As ' + FbType(ProcRec.RetType);
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
    Differ := DefNames.Count <> DeclNames.Count;
    if not Differ then
      for NameIdx := 0 to DefNames.Count - 1 do
        if DefNames[NameIdx] <> DeclNames[NameIdx] then
          Differ := True;
    if not Differ then
    begin
      // Имена те же, типы разные (form.bas: DECLARE SUB MainClose(Action
      // AS integer), SUB MainClose(Action) - DOUBLE по умолчанию): у
      // FreeBASIC объявление и заголовок должны совпадать - по DECLARE
      if CompareText(AParams, AProc.DeclParams) <> 0 then
      begin
        AParams := AProc.DeclParams;
        AAliases := AProc.DeclAliases;
      end;
      Exit;
    end;
    // Число параметров разное (RQdebugger: DECLARE SUB FrmClose без
    // параметров, SUB FrmClose (Action as integer)) или имена разные -
    // заголовок по DECLARE, лишние имена заголовка - локальные
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
    Suspect(AProc.Name + ': параметры в DECLARE (' + DeclNames.CommaText +
         ') и в заголовке (' + DefNames.CommaText + ') разные - как в ' +
         'RapidQ, в теле действуют параметры из DECLARE, лишние имена из ' +
         'заголовка - необъявленные переменные (0)');
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
    // BIND v TO This.Метод / Тип.Метод внутри TYPE своего компонента
    // (rapidq2.inc: BIND QFormEx.BindIndex TO QFormEx.WindowProc) -
    // адрес переходника, как у CODEPTR(This.Метод) (BindMethod)
    if not BindMethod(AToks, AFrom, ToIdx, NameIdx, ATo, KeyUp) then
      Error('BIND ... TO ' + RawText(AToks, NameIdx, ATo) + ': метод своего ' +
            'компонента - только внутри его TYPE (This.Метод или Тип.Метод)');
    Exit;
  end;
  ProcRec := FindProc(AToks[NameIdx].Up);
  if ProcRec <> nil then
    ProcRec.Used := True;
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

// Параметры двух DECLARE одной процедуры из DLL (строки ParseParams через
// запятую): совпадающие - как есть, различающиеся ByRef - "ByRef имя As
// Any". Число разное или различие не в типе ByRef - '' (не сводятся).
function MergeLibParams(const AFirst, ASecond: string): string;
var
  FirstList, SecondList: TStringList;
  ParamIdx, AsPos: Integer;
  FirstItem, SecondItem: string;
begin
  Result := '';
  FirstList := TStringList.Create;
  SecondList := TStringList.Create;
  try
    // Запятая внутри параметра не встречается: значения по умолчанию у
    // DECLARE из DLL нет
    FirstList.Text := StringReplace(AFirst, ',', #13#10, [rfReplaceAll]);
    SecondList.Text := StringReplace(ASecond, ',', #13#10, [rfReplaceAll]);
    if FirstList.Count <> SecondList.Count then
      Exit;
    for ParamIdx := 0 to FirstList.Count - 1 do
    begin
      FirstItem := Trim(FirstList[ParamIdx]);
      SecondItem := Trim(SecondList[ParamIdx]);
      if not SameText(FirstItem, SecondItem) then
      begin
        if (Pos('BYREF ', UpperCase(FirstItem)) <> 1) or
           (Pos('BYREF ', UpperCase(SecondItem)) <> 1) then
          Exit;
        AsPos := Pos(' AS ', UpperCase(FirstItem));
        if AsPos = 0 then
          Exit;
        FirstItem := Copy(FirstItem, 1, AsPos - 1) + ' As Any';
      end;
      FirstList[ParamIdx] := FirstItem;
    end;
    for ParamIdx := 0 to FirstList.Count - 1 do
    begin
      if ParamIdx > 0 then
        Result := Result + ', ';
      Result := Result + FirstList[ParamIdx];
    end;
  finally
    SecondList.Free;
    FirstList.Free;
  end;
end;

// DECLARE SUB|FUNCTION Имя [LIB "dll"] [ALIAS "имя"] [(параметры)] [AS тип]
procedure TRqFbConv.ProcessDeclare(var AToks: TToks; AFrom, ATo: Integer);
var
  KindIdx, NameIdx, TokIdx, OpenIdx, CloseIdx, TypeIdx: Integer;
  IsFunc: Boolean;
  LibText, AliasText, Params, RetType, StarLen, Header: string;
  LibName, AliasName: string;
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
  NoteDef('D||' + ProcRec.Name, 'DECLARE ' + AToks[NameIdx].Text);
  ProcRec.IsFunc := IsFunc;
  ProcRec.IsVariadic := IsWord(AToks, KindIdx, 'SUBI') or IsWord(AToks, KindIdx, 'FUNCTIONI');
  ProcRec.Declared := True;
  LibText := '';
  AliasText := '';
  TokIdx := NextSig(AToks, NameIdx + 1, ATo);
  LibName := '';
  AliasName := '';
  if IsWord(AToks, TokIdx, 'LIB') then
  begin
    TokIdx := NextSig(AToks, TokIdx + 1, ATo);
    if TokIdx >= 0 then
    begin
      LibText := ' Lib ' + AToks[TokIdx].Text;
      LibName := AToks[TokIdx].Text;
      if (Length(LibName) >= 2) and (LibName[1] = '"') then
        LibName := Copy(LibName, 2, Length(LibName) - 2);
    end;
    TokIdx := NextSig(AToks, TokIdx + 1, ATo);
  end;
  if IsWord(AToks, TokIdx, 'ALIAS') then
  begin
    TokIdx := NextSig(AToks, TokIdx + 1, ATo);
    if TokIdx >= 0 then
    begin
      AliasText := ' Alias ' + AToks[TokIdx].Text;
      AliasName := AToks[TokIdx].Text;
      if (Length(AliasName) >= 2) and (AliasName[1] = '"') then
        AliasName := Copy(AliasName, 2, Length(AliasName) - 2);
    end;
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
  // Повторный DECLARE без LIB с теми же параметрами - комментарием
  if (LibText = '') and (ProcRec.DeclPass = FPass) and
     (ProcRec.DeclAt <> FCurFile + '(' + IntToStr(FCurLine) + ')') and
     (ProcRec.DeclParams = Params) then
  begin
    Rebuild(AToks, AFrom, ATo, '''' + RawText(AToks, AFrom, ATo) +
            '   '' повторный DECLARE, первый - ' + ProcRec.DeclAt);
    Exit;
  end;
  if LibText = '' then
  begin
    ProcRec.DeclPass := FPass;
    ProcRec.DeclAt := FCurFile + '(' + IntToStr(FCurLine) + ')';
  end;
  // Повторный DECLARE с LIB и другими параметрами - комментарием, если
  // параметры сводятся (MergeLibParams); первый получит сведённые
  if (LibText <> '') and not ProcRec.IsVariadic then
  begin
    if (ProcRec.LibDeclPass = FPass) and
       (ProcRec.LibDeclAt <> FCurFile + '(' + IntToStr(FCurLine) + ')') and
       not SameText(ProcRec.LibDeclParams, Params) then
    begin
      if FPass = 1 then
      begin
        if ProcRec.LibMerged = '' then
          ProcRec.LibMerged := MergeLibParams(ProcRec.LibDeclParams, Params)
        else
          ProcRec.LibMerged := MergeLibParams(ProcRec.LibMerged, Params);
      end;
      if ProcRec.LibMerged <> '' then
      begin
        Rebuild(AToks, AFrom, ATo, '''' + RawText(AToks, AFrom, ATo) +
                '   '' повторный DECLARE с другими параметрами, первый - ' +
                ProcRec.LibDeclAt + ', параметры там: ' + ProcRec.LibMerged);
        Exit;
      end;
    end
    else if ProcRec.LibDeclPass <> FPass then
    begin
      ProcRec.LibDeclPass := FPass;
      ProcRec.LibDeclAt := FCurFile + '(' + IntToStr(FCurLine) + ')';
      if (FPass = 2) and (ProcRec.LibMerged <> '') then
        Params := ProcRec.LibMerged;
      ProcRec.LibDeclParams := Params;
    end;
  end;
  ProcRec.DeclParams := Params;
  ProcRec.DeclAliases := FParamAliases;
  if (LibText <> '') and not ProcRec.IsVariadic then
    ProcRec.LibKinds := FLibKinds
  else
    ProcRec.LibKinds := '';
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
  if (FPass = 2) and (LibText = '') and not ProcRec.HasBody and ProcRec.Used then
    SuspectOnce('NB|' + ProcRec.Name, AToks[KindIdx].Text + ' ' + AToks[NameIdx].Text +
      ': объявлен (DECLARE), но тела в программе нет - в переводе пустое ' +
      'тело (MissingBodies), вызов ничего не делает');
  ProcRec.DynLib := (LibText <> '') and not ProcRec.IsVariadic and
                    not IsImportLib(LibName);
  if ProcRec.DynLib then
  begin
    // Своя DLL: указатель на функцию и его значение из DLL при запуске
    // (строка DECLARE переносится в начало программы, HoistLine).
    // Имя в DLL - из ALIAS, без него - имя из DECLARE без суффикса
    if AliasName = '' then
      AliasName := BaseOf(AToks[NameIdx].Text);
    if IsFunc then
      Header := 'Dim Shared ' + ProcRec.FbName + ' As Function stdcall (' +
                Params + ') As ' + FbType(RetType)
    else
      Header := 'Dim Shared ' + ProcRec.FbName + ' As Sub stdcall (' + Params + ')';
    Header := Header + ' : ' + ProcRec.FbName + ' = RqDllProc("' + LibName +
              '", "' + AliasName + '", __FILE__, __LINE__)';
  end
  else if IsFunc then
    Header := 'Declare Function ' + ProcRec.FbName + LibText + AliasText +
              '(' + Params + ') As ' + FbType(RetType)
  else
    Header := 'Declare Sub ' + ProcRec.FbName + LibText + AliasText +
              '(' + Params + ')';
  Rebuild(AToks, AFrom, ATo, Header);
end;

// У библиотеки есть библиотека импорта FreeBASIC (RqImportLibText): имя
// без пути и без .dll
function TRqFbConv.IsImportLib(const ALibName: string): Boolean;
var
  NameUp: string;
begin
  NameUp := UpperCase(ExtractFileName(ALibName));
  if (Length(NameUp) > 4) and (Copy(NameUp, Length(NameUp) - 3, 4) = '.DLL') then
    Delete(NameUp, Length(NameUp) - 3, 4);
  Result := Pos(' ' + NameUp + ' ', ' ' + RqImportLibText + ' ') > 0;
end;

// TYPE Имя [EXTENDS Класс]. Свой компонент (EXTENDS; TYPE Имя AS Класс в
// главе 10.5 документации - то же): Type FreeBASIC целиком, со всеми
// полями и Declare методов (собраны в первом проходе), выводится здесь;
// после него #line возвращает номера строк исходника.
procedure TRqFbConv.ProcessTypeHeader(var AToks: TToks; AFrom, ATo: Integer);
var
  NameIdx, ExtIdx, BaseIdx, LineIdx, Found: Integer;
  Info: TRqTypeInfo;
  Block, Here: string;
begin
  NameIdx := NextSig(AToks, AFrom + 1, ATo);
  if (NameIdx < 0) or (AToks[NameIdx].Kind <> tkIdent) then
    Exit;
  FTypes.Add(AToks[NameIdx].Up);
  // TYPE с тем же именем второй раз (rapidq.inc, строка 1066, и
  // rapidq2.inc, строка 6372: TYPE QDebug с разными полями при
  // $INCLUDE "RAPIDQ.INC"): у типа одно описание, второе заменяет первое,
  // и методы первого теряют свои поля; во FreeBASIC два Type с одним
  // именем не собираются. Место первого объявления - в сообщении.
  Here := FCurFile + '(' + IntToStr(FCurLine) + ')';
  FCurTypePlace := Here;
  if FPass = 1 then
  begin
    if FTypeDefs.IndexOfName(AToks[NameIdx].Up) < 0 then
      FTypeDefs.Add(AToks[NameIdx].Up + '=' + Here);
  end
  else if (FTypeDefs.IndexOfName(AToks[NameIdx].Up) >= 0) and
          (FTypeDefs.Values[AToks[NameIdx].Up] <> Here) then
    Error('TYPE ' + AToks[NameIdx].Text + ' already defined - уже объявлен в ' +
          FTypeDefs.Values[AToks[NameIdx].Up] +
          '; перевод берёт последнее объявление, у методов первого его поля не найдутся');
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
  VarIdx, EqIdx, ToIdx, StepIdx, TokIdx, Depth, SavedBlocks: Integer;
  VarRec: TRqVar;
  TargetText, StartText, EndText, StepText, EndName, StepName: string;
begin
  VarIdx := NextSig(AToks, AFrom + 1, ATo);
  // "=", TO и STEP на верхнем уровне скобок
  EqIdx := -1;
  ToIdx := -1;
  StepIdx := -1;
  Depth := 0;
  for TokIdx := AFrom + 1 to ATo do
    if IsOp(AToks, TokIdx, '(') then
      Inc(Depth)
    else if IsOp(AToks, TokIdx, ')') then
      Dec(Depth)
    else if Depth = 0 then
    begin
      if (EqIdx < 0) and IsOp(AToks, TokIdx, '=') then
        EqIdx := TokIdx
      else if (EqIdx >= 0) and (ToIdx < 0) and IsWord(AToks, TokIdx, 'TO') then
        ToIdx := TokIdx
      else if (ToIdx >= 0) and IsWord(AToks, TokIdx, 'STEP') then
        StepIdx := TokIdx;
    end;
  SetLength(FForTargets, FForCount + 1);
  SetLength(FForSteps, FForCount + 1);
  FForTargets[FForCount] := '';
  FForSteps[FForCount] := '';
  Inc(FForCount);

  // Счётчик - не простая переменная (This.lx, a.b, a(1)): WHILE ... WEND.
  // Конец и шаг вычисляются один раз, как у FOR.
  if (VarIdx >= 0) and (EqIdx > VarIdx) and (ToIdx > EqIdx) and
     (NextSig(AToks, VarIdx + 1, EqIdx - 1) >= 0) then
  begin
    TargetText := RawText(AToks, VarIdx, EqIdx - 1);
    StartText := RawText(AToks, EqIdx + 1, ToIdx - 1);
    if StepIdx > 0 then
    begin
      EndText := RawText(AToks, ToIdx + 1, StepIdx - 1);
      StepText := RawText(AToks, StepIdx + 1, ATo);
    end
    else
    begin
      EndText := RawText(AToks, ToIdx + 1, ATo);
      StepText := '1';
    end;
    EndName := 'rq_forend' + IntToStr(FCurLine) + '#';
    StepName := 'rq_forstep' + IntToStr(FCurLine) + '#';
    FForTargets[FForCount - 1] := TargetText;
    FForSteps[FForCount - 1] := StepName;
    SavedBlocks := FModBlocks;
    Rebuild(AToks, AFrom, ATo, TranslateFragment(
      TargetText + ' = ' + StartText + ' : ' +
      EndName + ' = (' + EndText + ') : ' +
      StepName + ' = (' + StepText + ') : ' +
      'WHILE ((' + StepName + ' >= 0) AND (' + TargetText + ' <= ' + EndName +
      ')) OR ((' + StepName + ' < 0) AND (' + TargetText + ' >= ' + EndName +
      '))'));
    FModBlocks := SavedBlocks;
    Exit;
  end;

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
// NEXT [a [, b]]: закрывает столько FOR, сколько в нём имён (без имён -
// один). Закрывает FOR, переведённый в WHILE, - шаг и WEND вместо Next.
procedure TRqFbConv.ProcessNext(var AToks: TToks; AFrom, ATo: Integer);
var
  CloseCount, TokIdx, LoopIdx, SavedBlocks: Integer;
  AnyConverted: Boolean;
  OutText: string;
begin
  CloseCount := 1;
  for TokIdx := AFrom + 1 to ATo do
    if IsOp(AToks, TokIdx, ',') then
      Inc(CloseCount);
  AnyConverted := False;
  for LoopIdx := FForCount - 1 downto FForCount - CloseCount do
    if (LoopIdx >= 0) and (FForTargets[LoopIdx] <> '') then
      AnyConverted := True;
  if not AnyConverted then
  begin
    Dec(FForCount, CloseCount);
    if FForCount < 0 then
      FForCount := 0;
    ProcessExpr(AToks, AFrom + 1, ATo);
    Exit;
  end;
  // Есть переведённый: каждый закрывается по отдельности
  OutText := '';
  SavedBlocks := FModBlocks;
  for LoopIdx := 1 to CloseCount do
  begin
    if FForCount <= 0 then
      Break;
    Dec(FForCount);
    if OutText <> '' then
      OutText := OutText + ' : ';
    if FForTargets[FForCount] <> '' then
      OutText := OutText + TranslateFragment(FForTargets[FForCount] + ' = ' +
                 FForTargets[FForCount] + ' + ' + FForSteps[FForCount]) +
                 ' : Wend'
    else
      OutText := OutText + 'Next';
  end;
  FModBlocks := SavedBlocks;
  Rebuild(AToks, AFrom, ATo, OutText);
end;

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
// QUICKSORT(первый, последний, ASCEND|DESCEND) и без скобок ->
// RqQuickSort (rqrt.bi). Первый и последний элемент - одного массива:
// "span sort" через границу соседних массивов (otherdetail.html) в
// FreeBASIC не работает - массивы лежат в памяти каждый отдельно.
procedure TRqFbConv.ProcessQuickSort(var AToks: TToks; AFrom, ATo: Integer);
var
  FirstIdx, ArgFrom, ArgTo, OpenIdx, TokIdx, Depth, ArgCount: Integer;
  ArgStart: array[0..2] of Integer;
begin
  FirstIdx := NextSig(AToks, AFrom, ATo);
  AToks[FirstIdx].OutText := 'RqQuickSort';
  ArgFrom := FirstIdx + 1;
  ArgTo := ATo;
  OpenIdx := NextSig(AToks, FirstIdx + 1, ATo);
  if IsOp(AToks, OpenIdx, '(') and
     (MatchParen(AToks, OpenIdx, ATo) = PrevSig(AToks, ATo)) then
  begin
    ArgFrom := OpenIdx + 1;
    ArgTo := MatchParen(AToks, OpenIdx, ATo) - 1;
  end;

  // начала параметров
  ArgCount := 0;
  Depth := 0;
  TokIdx := NextSig(AToks, ArgFrom, ArgTo);
  if TokIdx >= 0 then
  begin
    ArgStart[0] := TokIdx;
    ArgCount := 1;
  end;
  while (TokIdx >= 0) and (TokIdx <= ArgTo) do
  begin
    if IsOp(AToks, TokIdx, '(') then
      Inc(Depth)
    else if IsOp(AToks, TokIdx, ')') then
      Dec(Depth)
    else if (Depth = 0) and IsOp(AToks, TokIdx, ',') then
    begin
      if ArgCount < 3 then
        ArgStart[ArgCount] := NextSig(AToks, TokIdx + 1, ArgTo);
      Inc(ArgCount);
    end;
    TokIdx := NextSig(AToks, TokIdx + 1, ArgTo);
  end;

  if ArgCount <> 3 then
    Error('QUICKSORT: ожидалось три параметра - первый и последний ' +
          'элемент массива и ASCEND или DESCEND')
  else if (ArgStart[0] >= 0) and (ArgStart[1] >= 0) and
          (AToks[ArgStart[0]].Kind = tkIdent) and
          (AToks[ArgStart[1]].Kind = tkIdent) and
          (AToks[ArgStart[0]].Up <> AToks[ArgStart[1]].Up) then
    Error('QUICKSORT ' + AToks[ArgStart[0]].Text + ' ... ' +
          AToks[ArgStart[1]].Text + ': элементы разных массивов ("span ' +
          'sort") - в FreeBASIC массивы не лежат в памяти подряд');
  ProcessExpr(AToks, FirstIdx + 1, ATo);
end;

// Первая запятая верхнего уровня в [AFrom..ATo]; нет - -1
function TRqFbConv.TopComma(const AToks: TToks; AFrom, ATo: Integer): Integer;
var
  TokIdx, Depth: Integer;
begin
  Result := -1;
  Depth := 0;
  for TokIdx := AFrom to ATo do
    if IsOp(AToks, TokIdx, '(') then
      Inc(Depth)
    else if IsOp(AToks, TokIdx, ')') then
      Dec(Depth)
    else if (Depth = 0) and IsOp(AToks, TokIdx, ',') then
    begin
      Result := TokIdx;
      Exit;
    end;
end;

// INITARRAY(Массив, значение, ...) и без скобок ->
// RqInitArray(Массив(), RqPList().Arg(значение)...) (rqrt.bi): первые
// элементы массива по порядку в памяти
procedure TRqFbConv.ProcessInitArray(var AToks: TToks; AFrom, ATo: Integer);
var
  FirstIdx, OpenIdx, ArgFrom, ArgTo, NameIdx, CommaIdx: Integer;
  VarRec: TRqVar;
begin
  FirstIdx := NextSig(AToks, AFrom, ATo);
  AToks[FirstIdx].OutText := 'RqInitArray';
  OpenIdx := NextSig(AToks, FirstIdx + 1, ATo);
  if IsOp(AToks, OpenIdx, '(') and
     (MatchParen(AToks, OpenIdx, ATo) = PrevSig(AToks, ATo)) then
  begin
    ArgFrom := OpenIdx + 1;
    ArgTo := MatchParen(AToks, OpenIdx, ATo) - 1;
  end
  else
  begin
    ArgFrom := FirstIdx + 1;
    ArgTo := ATo;
    AToks[FirstIdx].Post := AToks[FirstIdx].Post + '(';
    AToks[PrevSig(AToks, ATo)].Post := AToks[PrevSig(AToks, ATo)].Post + ')';
  end;
  NameIdx := NextSig(AToks, ArgFrom, ArgTo);
  CommaIdx := TopComma(AToks, ArgFrom, ArgTo);
  VarRec := nil;
  if (NameIdx >= 0) and (AToks[NameIdx].Kind = tkIdent) then
    VarRec := FindVar(AToks[NameIdx].Up);
  if (VarRec = nil) or not VarRec.IsArray or
     ((CommaIdx > 0) and (NextSig(AToks, NameIdx + 1, ArgTo) <> CommaIdx)) then
  begin
    Error('INITARRAY: первым параметром ожидалось имя массива: ' +
          RawText(AToks, ArgFrom, ArgTo));
    Exit;
  end;
  AToks[NameIdx].OutText := VarRec.FbName;
  AToks[NameIdx].Post := AToks[NameIdx].Post + '()';
  if (VarRec.Scope = '') and VarRec.Explicit then
    GlobalQualify(AToks, NameIdx);
  if CommaIdx > 0 then
  begin
    WrapVariadicArgs(AToks, CommaIdx + 1, ArgTo, FirstIdx, True);
    ProcessExpr(AToks, CommaIdx + 1, ArgTo);
  end
  else
    AToks[NameIdx].Post := AToks[NameIdx].Post + ', RqPList()';
end;

// Параметр - переменная-запись (TYPE без EXTENDS), её элемент массива или
// поле-запись своего компонента (This.Поле): ничего, кроме этого имени
function TRqFbConv.ArgIsRecord(const AToks: TToks; AFrom, ATo: Integer): Boolean;
var
  FirstIdx, NextIdx, FieldIdx, CloseIdx: Integer;
  TypeUp: string;
  VarRec: TRqVar;
begin
  Result := False;
  FirstIdx := NextSig(AToks, AFrom, ATo);
  if (FirstIdx < 0) or (AToks[FirstIdx].Kind <> tkIdent) then
    Exit;
  NextIdx := NextSig(AToks, FirstIdx + 1, ATo);
  if IsOp(AToks, NextIdx, '.') and (FCurType <> nil) and
     ((AToks[FirstIdx].Up = 'THIS') or (AToks[FirstIdx].Up = FCurType.Name)) then
  begin
    FieldIdx := NextSig(AToks, NextIdx + 1, ATo);
    if (FieldIdx < 0) or (AToks[FieldIdx].Kind <> tkIdent) then
      Exit;
    TypeUp := UpperCase(FCurType.MemberType.Values[AToks[FieldIdx].Up]);
    NextIdx := NextSig(AToks, FieldIdx + 1, ATo);
  end
  else
  begin
    VarRec := FindVar(AToks[FirstIdx].Up);
    if VarRec = nil then
      Exit;
    TypeUp := UpperCase(VarRec.RqType);
    if VarRec.IsArray and IsOp(AToks, NextIdx, '(') then
    begin
      CloseIdx := MatchParen(AToks, NextIdx, ATo);
      if CloseIdx < 0 then
        Exit;
      NextIdx := NextSig(AToks, CloseIdx + 1, ATo);
    end;
  end;
  Result := (NextIdx < 0) and (TypeUp <> '') and InList(FTypes, TypeUp) and
            (FindTypeInfo(TypeUp) = nil);
end;

// MEMCPY, MEMSET, MEMCMP с переменной-записью вместо адреса - адрес
// записи: так в rapidq2.inc (MEMCPY(gRQ2_MeasureItem, lParam, SIZEOF(...)),
// MEMSET(DevM, 0, SIZEOF(DevM))) и RapidFRM.inc (MEMSET(This.CC, ...)).
// Число (адрес в LONG, VARPTR(...)) - как есть.
procedure TRqFbConv.MemRecordArgs(var AToks: TToks; AHeadIdx, ATo: Integer);
var
  Up: string;
  OpenIdx, ArgFrom, ArgTo, TokIdx, Depth, StartIdx: Integer;

  procedure CheckArg(AArgFrom, AArgTo: Integer);
  var
    FirstTok, LastTok: Integer;
  begin
    if not ArgIsRecord(AToks, AArgFrom, AArgTo) then
      Exit;
    FirstTok := NextSig(AToks, AArgFrom, AArgTo);
    LastTok := PrevSig(AToks, AArgTo);
    AToks[FirstTok].Pre := 'Cast(Integer, @' + AToks[FirstTok].Pre;
    AToks[LastTok].Post := AToks[LastTok].Post + ')';
  end;

begin
  Up := AToks[AHeadIdx].Up;
  if (Up <> 'MEMCPY') and (Up <> 'MEMSET') and (Up <> 'MEMCMP') then
    Exit;
  ArgFrom := AHeadIdx + 1;
  ArgTo := ATo;
  OpenIdx := NextSig(AToks, AHeadIdx + 1, ATo);
  if IsOp(AToks, OpenIdx, '(') and (MatchParen(AToks, OpenIdx, ATo) > 0) then
  begin
    ArgFrom := OpenIdx + 1;
    ArgTo := MatchParen(AToks, OpenIdx, ATo) - 1;
  end;
  Depth := 0;
  StartIdx := ArgFrom;
  for TokIdx := ArgFrom to ArgTo do
    if IsOp(AToks, TokIdx, '(') then
      Inc(Depth)
    else if IsOp(AToks, TokIdx, ')') then
      Dec(Depth)
    else if (Depth = 0) and IsOp(AToks, TokIdx, ',') then
    begin
      CheckArg(StartIdx, TokIdx - 1);
      StartIdx := TokIdx + 1;
    end;
  if StartIdx <= ArgTo then
    CheckArg(StartIdx, ArgTo);
end;

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
  // имя, у которого уже есть замена для членов (POINTER -> PointerAddr,
  // RqMemberMapText): та же - Объект.Имя снаружи переводится по ней
  else if FMemberMap.IndexOf(UpperCase(ADisplay)) >= 0 then
    Result := FMemberMap.Get(UpperCase(ADisplay))
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
  ProcRec: TRqProc;
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
  // Функция читает RESULT - его локальная копия (ProcessIdent)
  ProcRec := FindProc(AScope);
  if (ProcRec <> nil) and ProcRec.IsFunc and ProcRec.ResultRead then
    Result := Result + ' : Dim rq_result As ' + FbType(ProcRec.RetType);
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
        // Имя предка тоже (rapidq2.inc, QFormEx EXTENDS QFORM: в методе
        // QForm.Icon) - как This: у класса RapidQ других объектов с этим
        // именем нет
        if ((Up = FCurType.Name) or (Up = 'THIS') or
            ((FCurType.BaseClass <> '') and (Up = FCurType.BaseClass))) and
           IsOp(Toks, AfterIdx, '.') then
        begin
          Toks[RefIdx].Text := 'This';
          Changed := True;
          Continue;
        end;
        if FTypeBody <> 2 then
          Continue;
        // CONSTRUCTOR: член без имени объекта. Имя типа (TYPE Grid в
        // программе) пропускается, только если у компонента нет такого
        // члена: поле Grid AS QSTRINGGRID важнее
        if IsLocalName(Up) or (InList(FTypes, Up) and (FCurType.Kind(Up) = #0)) then
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
  NoteDef('M|' + FCurTypePlace + '|' + NameUp, FCurType.Display + '.' + Display);
  FCurProcPlace := FCurFile + '(' + IntToStr(FCurLine) + ')';
  ProcRec.IsFunc := IsFunc;
  ProcRec.IsVariadic := (KindUp = 'SUBI') or (KindUp = 'FUNCTIONI');
  FCurProc := ProcRec;
  FCurProcPlace := FCurFile + '(' + IntToStr(FCurLine) + ')';
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
      FCurType.MethParams.Add(NameUp + '=' + Params);
      FCurType.Decls.Add('Declare ' + DeclText);
      if ProcRec.IsVariadic then
      begin
        FCurType.Variadic.Add(NameUp);
        FCurType.ParamCounts.Values[NameUp] := '-1';
      end;
      // Объект.Delete, Объект.Err$ снаружи - тем же именем
      if FbName <> Display then
        FMemberMap.Put(NameUp, FbName);
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
  FCurProcPlace := FCurFile + '(' + IntToStr(FCurLine) + ')';
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
  FCurProcPlace := FCurFile + '(' + IntToStr(FCurLine) + ')';
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
  NoteDef('M|' + FCurTypePlace + '|' + NameUp, FCurType.Display + '.' + Display);
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
      FMemberMap.Put(NameUp, FbName);
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

// CODEPTR(This.Метод) / CODEPTR(Тип.Метод) внутри TYPE своего компонента.
// Windows вызывает процедуру по адресу без объекта, поэтому адрес берётся у
// переходника Тип__RqCb_Метод (обычная процедура с параметрами метода),
// а объект запоминается в Тип__RqCbObj_Метод в момент взятия адреса:
//   CODEPTR(This.Метод) -> Тип__RqCbAddr_Метод(@This)
// Переходник вызывает метод у последнего запомненного объекта.
function TRqFbConv.CodePtrMethod(var AToks: TToks; AIdx, AOpen, AClose: Integer): Boolean;
var
  OwnerIdx, DotIdx, MethIdx, TokIdx: Integer;
  MethUp: string;
begin
  Result := False;
  if FCurType = nil then
    Exit;
  OwnerIdx := NextSig(AToks, AOpen + 1, AClose);
  if (OwnerIdx < 0) or (OwnerIdx >= AClose) then
    Exit;
  DotIdx := NextSig(AToks, OwnerIdx + 1, AClose);
  if (DotIdx < 0) or not IsOp(AToks, DotIdx, '.') then
    Exit;
  MethIdx := NextSig(AToks, DotIdx + 1, AClose);
  if (MethIdx < 0) or (AToks[MethIdx].Kind <> tkIdent) or
     (NextSig(AToks, MethIdx + 1, AClose) <> AClose) then
    Exit;
  if not IsWord(AToks, OwnerIdx, 'THIS') and
     not IsWord(AToks, OwnerIdx, FCurType.Name) then
    Exit;
  MethUp := AToks[MethIdx].Up;
  if (FPass = 2) and not (FCurType.Kind(MethUp) in ['M', 'N']) then
  begin
    Error(AToks[AIdx].Text + RawText(AToks, AOpen, AClose) +
          ': ' + AToks[MethIdx].Text + ' - не SUB и не FUNCTION типа ' +
          FCurType.Display);
    Result := True;
    Exit;
  end;
  if (FPass = 1) and (FCurType.CbThunks.IndexOf(MethUp) < 0) then
    FCurType.CbThunks.Add(MethUp);
  Rebuild(AToks, AIdx, AClose, FCurType.Display + '__RqCbAddr_' +
          MemberFbName(AToks[MethIdx].Text) + '(@This)');
  // токены в скобках уже выведены - дальше по выражению их не обрабатывать
  for TokIdx := AOpen to AClose do
    AToks[TokIdx].Kind := tkSpace;
  Result := True;
end;

// BIND v TO This.Метод / Тип.Метод внутри TYPE своего компонента ->
// v = Тип__RqCbAddr_Метод(@This): адрес переходника (см. CodePtrMethod),
// шаблон для CALLFUNC - сам метод (у переходника те же параметры)
function TRqFbConv.BindMethod(var AToks: TToks; AFrom, AToIdx, AOwnerIdx, ATo: Integer;
                              const AKeyUp: string): Boolean;
var
  DotIdx, MethIdx, TokIdx: Integer;
  MethUp: string;
  MethProc: TRqProc;
begin
  Result := False;
  if FCurType = nil then
    Exit;
  DotIdx := NextSig(AToks, AOwnerIdx + 1, ATo);
  MethIdx := NextSig(AToks, DotIdx + 1, ATo);
  if (MethIdx < 0) or (AToks[MethIdx].Kind <> tkIdent) or
     (NextSig(AToks, MethIdx + 1, ATo) >= 0) then
    Exit;
  if not IsWord(AToks, AOwnerIdx, 'THIS') and
     not IsWord(AToks, AOwnerIdx, FCurType.Name) then
    Exit;
  Result := True;
  MethUp := AToks[MethIdx].Up;
  if (FPass = 2) and not (FCurType.Kind(MethUp) in ['M', 'N']) then
  begin
    Error('BIND ... TO ' + RawText(AToks, AOwnerIdx, ATo) + ': ' +
          AToks[MethIdx].Text + ' - не SUB и не FUNCTION типа ' + FCurType.Display);
    Exit;
  end;
  if (FPass = 1) and (FCurType.CbThunks.IndexOf(MethUp) < 0) then
    FCurType.CbThunks.Add(MethUp);
  MethProc := FindProc(FCurType.Name + '.' + MethUp);
  if MethProc <> nil then
    FBinds.Values[AKeyUp] := MethProc.Name;
  AToks[AFrom].OutText := '';
  if (AFrom + 1 <= ATo) and (AToks[AFrom + 1].Kind = tkSpace) then
    AToks[AFrom + 1].OutText := '';
  ProcessExpr(AToks, AFrom + 1, AToIdx - 1);
  Rebuild(AToks, AToIdx, ATo, '= ' + FCurType.Display + '__RqCbAddr_' +
          MemberFbName(AToks[MethIdx].Text) + '(@This)');
  for TokIdx := AToIdx + 1 to ATo do
    AToks[TokIdx].Kind := tkSpace;
end;

// Переходники для CODEPTR(This.Метод) (первый проход, END TYPE)
procedure TRqFbConv.AddCodePtrThunks;
const
  RqCbSlots = 16;  // объектов с отдельным переходником на один метод
var
  ThunkIdx, CharIdx, Depth, SlotIdx: Integer;
  MethUp, MethFb, Params, Args, Piece, CbName, ObjName, AddrName, RetText: string;
  Kind: Char;

  // имя параметра из "ByVal Имя As Тип" / "ByRef Имя() As Тип"
  procedure AddArg(const APiece: string);
  var
    Words: string;
    SpacePos: Integer;
  begin
    Words := Trim(APiece);
    if Words = '' then
      Exit;
    if (UpperCase(Copy(Words, 1, 6)) = 'BYVAL ') or
       (UpperCase(Copy(Words, 1, 6)) = 'BYREF ') then
      Words := Trim(Copy(Words, 7, MaxInt));
    SpacePos := Pos(' ', Words);
    if SpacePos > 0 then
      Words := Copy(Words, 1, SpacePos - 1);
    if Pos('(', Words) > 0 then
      Words := Copy(Words, 1, Pos('(', Words) - 1) + '()';
    if Args <> '' then
      Args := Args + ', ';
    Args := Args + Words;
  end;

begin
  for ThunkIdx := 0 to FCurType.CbThunks.Count - 1 do
  begin
    MethUp := FCurType.CbThunks[ThunkIdx];
    Kind := FCurType.Kind(MethUp);
    if not (Kind in ['M', 'N']) then
      Continue;
    MethFb := FCurType.MemberFb.Values[MethUp];
    if MethFb = '' then
      MethFb := MethUp;
    Params := FCurType.MethParams.Values[MethUp];
    Args := '';
    Piece := '';
    Depth := 0;
    for CharIdx := 1 to Length(Params) do
    begin
      if Params[CharIdx] = '(' then
        Inc(Depth)
      else if Params[CharIdx] = ')' then
        Dec(Depth);
      if (Params[CharIdx] = ',') and (Depth = 0) then
      begin
        AddArg(Piece);
        Piece := '';
      end
      else
        Piece := Piece + Params[CharIdx];
    end;
    AddArg(Piece);
    CbName := FCurType.Display + '__RqCb_' + MethFb;
    ObjName := FCurType.Display + '__RqCbObj_' + MethFb;
    AddrName := FCurType.Display + '__RqCbAddr_' + MethFb;
    // у каждого объекта свой переходник (в RapidQ у каждого объекта свой
    // адрес метода): RqCbSlots штук, объект - в своём элементе массива
    FCurType.After.Add('Dim Shared ' + ObjName + '(0 To ' + IntToStr(RqCbSlots - 1) +
                       ') As ' + FCurType.Display + ' Ptr');
    FCurType.After.Add('Declare Function ' + AddrName + '(ByVal RqObj As ' +
                       FCurType.Display + ' Ptr) As Integer');
    if Kind = 'N' then
      RetText := FbType(FCurType.MemberType.Values[MethUp])
    else
      RetText := '';
    for SlotIdx := 0 to RqCbSlots - 1 do
    begin
      if Kind = 'N' then
      begin
        FCurType.After.Add('Declare Function ' + CbName + '_' + IntToStr(SlotIdx) +
                           '(' + Params + ') As ' + RetText);
        FCurType.Tail.Add('Function ' + CbName + '_' + IntToStr(SlotIdx) + '(' + Params +
                          ') As ' + RetText + ' : Return ' + ObjName + '(' +
                          IntToStr(SlotIdx) + ')->' + MethFb + '(' + Args +
                          ') : End Function');
      end
      else
      begin
        FCurType.After.Add('Declare Sub ' + CbName + '_' + IntToStr(SlotIdx) +
                           '(' + Params + ')');
        FCurType.Tail.Add('Sub ' + CbName + '_' + IntToStr(SlotIdx) + '(' + Params +
                          ') : ' + ObjName + '(' + IntToStr(SlotIdx) + ')->' + MethFb +
                          '(' + Args + ') : End Sub');
      end;
    end;
    // свой элемент у объекта, который уже брал адрес, иначе первый свободный;
    // все заняты - последний (переходник переходит к новому объекту)
    FCurType.Tail.Add('Function ' + AddrName + '(ByVal RqObj As ' + FCurType.Display +
                      ' Ptr) As Integer');
    FCurType.Tail.Add('  Dim RqSlot As Integer');
    FCurType.Tail.Add('  For RqSlot = 0 To ' + IntToStr(RqCbSlots - 1) + ' : If ' +
                      ObjName + '(RqSlot) = RqObj Then Exit For');
    FCurType.Tail.Add('  Next');
    FCurType.Tail.Add('  If RqSlot > ' + IntToStr(RqCbSlots - 1) + ' Then');
    FCurType.Tail.Add('    For RqSlot = 0 To ' + IntToStr(RqCbSlots - 1) + ' : If ' +
                      ObjName + '(RqSlot) = 0 Then Exit For');
    FCurType.Tail.Add('    Next');
    FCurType.Tail.Add('    If RqSlot > ' + IntToStr(RqCbSlots - 1) + ' Then RqSlot = ' +
                      IntToStr(RqCbSlots - 1));
    FCurType.Tail.Add('  End If');
    FCurType.Tail.Add('  ' + ObjName + '(RqSlot) = RqObj');
    FCurType.Tail.Add('  Select Case RqSlot');
    for SlotIdx := 0 to RqCbSlots - 1 do
      FCurType.Tail.Add('  Case ' + IntToStr(SlotIdx) + ' : Return Cast(Integer, @' +
                        CbName + '_' + IntToStr(SlotIdx) + ')');
    FCurType.Tail.Add('  End Select');
    FCurType.Tail.Add('End Function');
  end;
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
         ((FCurType.ParamCounts.Values[MethUp] = IntToStr(ArgCount)) or
          (FCurType.ParamCounts.Values[MethUp] = IntToStr(ArgCount + 1))) then
        for ArgIdx := 1 to ArgCount do
        begin
          if Args <> '' then
            Args := Args + ', ';
          Args := Args + 'RqArg' + IntToStr(ArgIdx);
        end;
      // У метода на параметр больше, чем у события, - последний Sender
      // (rapidq2.inc: SUB columnclick(hcapt AS QCOOLBTN) на OnClick кнопки
      // заголовка, hcapt.caption - подпись нажатой)
      if FCurType.ParamCounts.Values[MethUp] = IntToStr(ArgCount + 1) then
      begin
        if Args <> '' then
          Args := Args + ', ';
        Args := Args + 'Sender';
      end;
      MethFb := FCurType.MemberFb.Values[MethUp];
      if MethFb = '' then
        MethFb := MethUp;
      if Copy(CompFb, 1, 1) = '*' then
      begin
        // поле - массив: объект - последний, присвоивший событие
        System.Delete(CompFb, 1, 1);
        SelfText := FCurType.Display + '__RqThObj_' + CompFb;
        if FCurType.After.IndexOf('Dim Shared ' + SelfText + ' As ' +
                                  FCurType.Display + ' Ptr') < 0 then
          FCurType.After.Add('Dim Shared ' + SelfText + ' As ' +
                             FCurType.Display + ' Ptr');
      end
      else if CompFb = '' then
        SelfText := 'Cast(' + FCurType.Display + ' Ptr, Cast(Any Ptr, @Sender))'
      else
        SelfText := 'Cast(' + FCurType.Display + ' Ptr, Cast(Any Ptr, ' +
          'Cast(UByte Ptr, Cast(Any Ptr, @Sender)) - OffsetOf(' +
          FCurType.Display + ', ' + CompFb + ')))';
      FCurType.After.Add('Declare Sub ' + ThunkName + '(' + Params + ')');
      FCurType.Tail.Add('Sub ' + ThunkName + '(' + Params + ') : ' + SelfText +
                        '->' + MethFb + '(' + Args + ') : End Sub');
    end;
    AddCodePtrThunks;
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
  SigCount, TokIdx, RhsFirst, RhsLast, RhsDot, MethIdx, CompIdx, OpenIdx,
    CloseIdx, DotIdx, EventIdx: Integer;
  MemberUp, CompUp, CompFb, ClassUp, EventDisplay, MethUp, ThunkName: string;
  Kind: Char;
begin
  Result := False;
  // This.Поле(i).OnXxx = This.Метод: поле - массив компонентов (rapidq2.inc,
  // QListViewEx.draw: .ColHeader(.ix).OnClick = .columnclick). Объект в
  // переходнике - по смещению не найти (индекс неизвестен): берётся
  // последний, присвоивший событие (Тип__RqThObj_Поле), как у CODEPTR.
  CompIdx := NextSig(AToks, NextSig(AToks, AFirst, AEq - 1) + 1, AEq - 1);
  if IsWord(AToks, NextSig(AToks, AFirst, AEq - 1), 'THIS') and
     IsOp(AToks, CompIdx, '.') then
  begin
    CompIdx := NextSig(AToks, CompIdx + 1, AEq - 1);
    OpenIdx := NextSig(AToks, CompIdx + 1, AEq - 1);
    if (CompIdx >= 0) and (AToks[CompIdx].Kind = tkIdent) and
       IsOp(AToks, OpenIdx, '(') then
    begin
      CloseIdx := MatchParen(AToks, OpenIdx, AEq - 1);
      DotIdx := NextSig(AToks, CloseIdx + 1, AEq - 1);
      EventIdx := NextSig(AToks, DotIdx + 1, AEq - 1);
      RhsFirst := NextSig(AToks, AEq + 1, ATo);
      RhsLast := PrevSig(AToks, ATo);
      RhsDot := NextSig(AToks, RhsFirst + 1, ATo);
      MethIdx := NextSig(AToks, RhsDot + 1, ATo);
      if (CloseIdx > 0) and IsOp(AToks, DotIdx, '.') and (EventIdx >= 0) and
         (AToks[EventIdx].Kind = tkIdent) and
         (NextSig(AToks, EventIdx + 1, AEq - 1) < 0) and
         IsEventName(AToks[EventIdx].Up) and
         IsWord(AToks, RhsFirst, 'THIS') and IsOp(AToks, RhsDot, '.') and
         (MethIdx = RhsLast) and (AToks[MethIdx].Kind = tkIdent) and
         not (FCurType.Kind(AToks[MethIdx].Up) in ['F', 'P', 'E']) and
         (FCurType.Kind(AToks[CompIdx].Up) = 'F') then
      begin
        CompUp := AToks[CompIdx].Up;
        CompFb := FCurType.MemberFb.Values[CompUp];
        ClassUp := FCurType.MemberType.Values[CompUp];
        EventDisplay := AToks[EventIdx].Text;
        MethUp := AToks[MethIdx].Up;
        ThunkName := FCurType.Display + '__RqTh_' + CompFb + '_' +
                     EventDisplay + '_' + MemberFbName(AToks[MethIdx].Text);
        if FPass = 1 then
          AddThunk(ThunkName, '*' + CompFb, ClassUp, EventDisplay, MethUp);
        ProcessExpr(AToks, AFirst, AEq - 1);
        Rebuild(AToks, RhsFirst, RhsLast, '@' + ThunkName + ' : ' +
                FCurType.Display + '__RqThObj_' + CompFb + ' = @This');
        Result := True;
        Exit;
      end;
    end;
  end;
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
// SUB/FUNCTION, объявленные DECLARE (не LIB), без тела нигде в программе,
// но с обращением (вызов, обработчик события; без обращений fbc тело не
// нужно) (RQdebugger: DECLARE SUB ComError, PortOpen, PortClosed,
// StringWritten, StringRead - назначены событиями MyPort, тел нет). RapidQ
// такое компилирует, у FreeBASIC - undefined reference при сборке. Здесь -
// пустые тела в конце главного файла (FUNCTION возвращает 0 / ""),
// предупреждение - в ProcessDeclare.
function TRqFbConv.MissingBodies: string;
var
  ProcIdx: Integer;
  ProcRec: TRqProc;
begin
  Result := '';
  for ProcIdx := 0 to FProcs.Count - 1 do
  begin
    ProcRec := TRqProc(FProcs.Objects[ProcIdx]);
    if not ProcRec.Declared or ProcRec.HasBody or not ProcRec.Used then
      Continue;
    if Result = '' then
      Result := ''' Объявлены DECLARE, тела в программе нет - пустые (RqToFb)' + CrLf;
    if ProcRec.IsFunc then
    begin
      Result := Result + 'Function ' + ProcRec.FbName + '(' + ProcRec.DeclParams +
                ') As ' + FbType(ProcRec.RetType) + CrLf;
      if UpperCase(ProcRec.RetType) = 'STRING' then
        Result := Result + '    Function = ""' + CrLf
      else if IsNumericType(ProcRec.RetType) then
        Result := Result + '    Function = 0' + CrLf;
      Result := Result + 'End Function' + CrLf;
    end
    else
      Result := Result + 'Sub ' + ProcRec.FbName + '(' + ProcRec.DeclParams + ')' +
                CrLf + 'End Sub' + CrLf;
  end;
end;

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
  // CONST и DECLARE ... LIB со всей программы - до первого обращения
  // (HoistLine); на своих местах они - комментарии
  for VarIdx := 0 to FHoistConsts.Count - 1 do
    Result := Result + FHoistConsts[VarIdx] + CrLf;
  for VarIdx := 0 to FHoistDecls.Count - 1 do
    Result := Result + FHoistDecls[VarIdx] + CrLf;
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

  // Имя объявлено (в своей SUB или в модуле) - запись не нужна
  function BaseDeclared(const AScope, ABase: string): Boolean;
  var
    BaseIdx: Integer;
  begin
    Result := (FVars.Find(AScope + '|' + ABase, BaseIdx) and
               TRqVar(FVars.Objects[BaseIdx]).Explicit) or
              (FVars.Find('|' + ABase, BaseIdx) and
               TRqVar(FVars.Objects[BaseIdx]).Explicit);
  end;

begin
  for VarIdx := FVars.Count - 1 downto 0 do
  begin
    VarRec := TRqVar(FVars.Objects[VarIdx]);
    if (VarRec.Scope <> '') and not VarRec.Explicit and
       FVars.Find('|' + VarRec.Name, Found) then
    begin
      VarRec.Free;
      FVars.Delete(VarIdx);
    end
    // Имя.Свойство, а Имя объявлено ниже по тексту (COMPORT.CMP:
    // MyPort.Handle в методе, DIM MyPort AS COMPORT - в главном файле):
    // в первом проходе оно было ещё неизвестно, во втором это объект
    else if (VarRec.DotBase <> '') and not VarRec.Explicit and
            BaseDeclared(VarRec.Scope, VarRec.DotBase) then
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
  SavedLine, SavedBlocks: Integer;
  SavedProc: TRqProc;
  StrJoins, CutPos, JoinIdx: Integer;
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
  SavedBlocks := FModBlocks;
  FCurFile := AFileName;
  FCurProc := nil;
  FModBlocks := 0;
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
    Report(AFileName);
    LineIdx := 0;
    CreateBase := FCreateStack.Count;
    while LineIdx < Lines.Count do
    begin
      StartIdx := LineIdx;
      Text := Lines[LineIdx];
      StrJoins := 0;
      while LineIdx + 1 < Lines.Count do
      begin
        if EndsWithContinue(Text) then
        begin
          Inc(LineIdx);
          Text := Text + CrLf + Lines[LineIdx];
        end
        // "_" в конце незакрытой строки в кавычках: строка продолжается
        // на следующей, "_" и перевод строки в неё не входят. В
        // FreeBASIC строка в кавычках - в одной строке файла, поэтому
        // склеиваем здесь; число строк вывода - пустыми строками после
        // оператора
        else if StrContinues(Text, CutPos) then
        begin
          Inc(LineIdx);
          Text := Copy(Text, 1, CutPos - 1) + Lines[LineIdx];
          Inc(StrJoins);
        end
        else
          Break;
      end;
      FCurFile := AFileName;
      FCurLine := StartIdx + 1;
      FLostLines := 0;
      ProcessLine(Text, OutText);
      for JoinIdx := 1 to StrJoins do
        OutText := OutText + CrLf;
      OutLines.Add(OutText);
      Inc(LineIdx);
      // Строки продолжения (_) - тоже строки файла
      Inc(FPassLines, LineIdx - StartIdx);
      if FPassLines - FProgLast >= 200 then
        Report(AFileName);
      if FAborted then
        Break;
    end;
    // Перевод остановлен: файл не дописан, проверки конца файла и запись
    // вывода не нужны
    if FAborted then
      Exit;
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
      begin
        OutLines.Insert(0, MainHeader + '#line 0 "' + AFileName + '"');
        OutLines.Add(MissingBodies);
      end
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
    FModBlocks := SavedBlocks;
  end;
end;

// Сообщение о ходе перевода получателю (RqToFbConvertEx). Получатель
// вернул False - перевод останавливается (FAborted).
procedure TRqFbConv.Report(const AFile: string);
begin
  FProgLast := FPassLines;
  if Assigned(FProgress) and not FAborted then
    if not FProgress(FPass, AFile, FPassLines, FPass1Lines) then
      FAborted := True;
end;

function TRqFbConv.Run(const AMainFile: string; var AResult: TRqFbResult): Boolean;
var
  PassIdx: Integer;
begin
  FMainFile := ExpandFileName(AMainFile);
  FOpt.OutDir := ExpandFileName(FOpt.OutDir);
  FSourceMode := '';
  FPass1Lines := 0;
  FHoistKeys.Clear;
  FHoistConsts.Clear;
  FHoistDecls.Clear;
  for PassIdx := 1 to 2 do
  begin
    if FAborted then
      Break;
    FPass := PassIdx;
    FForCount := 0;
    FPassLines := 0;
    FProgLast := 0;
    FDoneFiles.Clear;
    FOutNames.Clear;
    FDefines.Clear;
    FDefinePlaces.Clear;
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
    // Конец прохода: полоса хода - до конца прохода
    Report(FMainFile);
    if PassIdx = 1 then
    begin
      FPass1Lines := FPassLines;
      EndOfPass1;
      // режим из исходника - сильнее настройки
      if FSourceMode = 'SMART' then
        FOpt.Mode := rfmSmart
      else if FSourceMode = 'COMPAT' then
        FOpt.Mode := rfmCompat;
    end;
  end;
  if FAborted then
  begin
    // Сообщения пишутся только во втором проходе - остановить могли в первом
    FPass := 2;
    FCurFile := FMainFile;
    FCurLine := 0;
    Error('перевод остановлен');
  end
  else if Length(FConds) > 0 then
  begin
    FCurFile := FMainFile;
    Error('$IFDEF без $ENDIF');
  end;
  AResult.AppType := FAppType;
  AResult.Mode := FOpt.Mode;
  AResult.ErrorCount := FErrors;
  AResult.WarningCount := FWarnings;
  AResult.SuspectCount := FSuspects;
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
  NoteDef('V||' + VarRec.Name, '$RESOURCE ' + AToks[NameIdx].Text);
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
begin
  Result := RqToFbConvertEx(AMainFile, AOptions, AMessages, AResult, nil);
end;

function RqToFbConvertEx(const AMainFile: string; const AOptions: TRqFbOptions;
                         AMessages: TStrings; var AResult: TRqFbResult;
                         AProgress: TRqFbProgress): Boolean;
var
  Conv: TRqFbConv;
begin
  Conv := TRqFbConv.Create(AOptions, AMessages);
  try
    Conv.FProgress := AProgress;
    Result := Conv.Run(AMainFile, AResult);
  finally
    Conv.Free;
  end;
end;

end.
