'$include "C:\bas\RapidQ\RQIDE\debugWindow35.bas"


'$include "C:\_F\bas\rapidq\RQIDE\debugWindow36.bas" RapidFRMtst.bas

'-----------------------------------------------------------------------------------------------------------------
'  PROJECT: RapidFRM.exe
'  Form Designer/Editor for RapidQ Basic (with limited support for FreeBasic)
'  Copyright (c) 2009-13 Don Homans
'
'  CONTRIBUTORS:    Jordi Ramos - original code base (v1.00 assigned)
'                   JohnK - Floating component panel
'                   Andrew Shelkovenko - up to 1.90b version
'  AUTHOR:          d_homans@yahoo.com.au
'  VERSION:         1.85 (up to 1.90b)
'  DATE:            27 Dec 2021
'  COMMENT:
'-----------------------------------------------------------------------------------------------------------------
'$APPTYPE GUI
'$TYPECHECK ON
$OPTION ICON "RapidFRM.ico"                                  ' Using RapidQ icon

$INCLUDE "inc\RapidQ2.inc"
$INCLUDE "inc\RapidFRM.inc"                                             ' My MouseHook, ColorDialog & TabControl stuff
'$INCLUDE "conversion.inc"

$DEFINE MAXTOOLBTNS     15
$INCLUDE "QToolBarEX.inc"                                           ' My toolbar component (with QImageListEX.inc)
$include "Object\QStatusBarEx.inc"

$RESOURCE ObjData AS "component.data"                               ' Resource(0) used in initialise()
$RESOURCE HelpData AS "Help.data"                                   ' Resource(1) used in initialise()
$RESOURCE BlankIco AS "images\Blank.ico"                            ' Blank form icon
$RESOURCE TBar1 AS "images\ToolBar1.bmp"
$RESOURCE TBar2 AS "images\ToolBar2.bmp"
$RESOURCE TBar3 AS "images\ToolBar3.bmp"
$RESOURCE TBar4 AS "images\ToolBar4.bmp"
$RESOURCE TBar5 AS "images\ToolBar5.bmp"
$RESOURCE XBtns AS "images\ToolBar6.bmp"

$INCLUDE "RichEdPopUp.inc"
'$INCLUDE "QColorDialog.inc"
$Include "constants.inc"
'$include "QColorButton.inc"
$include "Object\QINI.inc"
'$include "Object\QStatusBarEx.inc"
'include "Form.inc"

print q23ewqwe=23234


CONST VER="vb274 Dec 2021"
CONST QU=CHR$(34)

$DEFINE STAND_ALONE     0                                           '
$DEFINE INPUT_FILE      1                                           ' Modes of operation
$DEFINE INPUT_CLIPBRD   2                                           '


$DEFINE MAX_rqOBJECTS     128 ' max RQ components supported

$DEFINE MAX_OBJECTS     128                                          ' Limit of components (including forms) can de added
$DEFINE MAX_FORMS       16                                           ' This limit seems reasonable
$DEFINE MAX_MENUS       8                                           ' Overkill?

$DEFINE NON_VISIBLE     30                                          ' 0->29 Visible, 30->55 non-visible
$DEFINE MAX_TOOLBTNS    55                                          ' 5 TABs: 15 + 14 + 11 + 4 + 11

$DEFINE MAINMENU        1
$DEFINE POPMENU         2

$DEFINE SWP_NOSIZE      1
$DEFINE SWP_NOMOVE      2
$DEFINE SWP_NOZORDER    4
$DEFINE SWP_DRAWFRAME   &H20

CONST FLAGS=(SWP_NOSIZE + SWP_NOMOVE)
CONST SW_FLAGS=(SWP_NOZORDER + SWP_DRAWFRAME)
CONST SWP_FLAGS=(SW_FLAGS + SWP_NOMOVE)

$DEFINE DBG_INPUT_STREAM

Declare Function TextOut Lib "gdi32" Alias "TextOutA" (ByVal hdc As Long, ByVal x As Long, ByVal y As Long, ByVal lpString As String, ByVal nCount As Long) As Long

'Declare Function SelectObject Lib "gdi32" Alias "SelectObject" (ByVal hdc As Long, ByVal hObject As Long) As Long
Declare Function SetTextColor Lib "gdi32" Alias "SetTextColor" (ByVal hdc As Long, ByVal crColor As Long) As Long

Declare function GetNewObjectID (ObjType as string) as long 'QForm
declare sub GetOperators1 (Oper$() as string,OperPos() as integer, OperLen() as integer, SrcTxt$ as string,NumOpers as long)
declare sub GetOpersList (~SrcD as Qrichedit,StringList1 as QStringList)
DECLARE FUNCTION WaitForSingleObject Lib "kernel32" Alias "WaitForSingleObject" (ByVal hHandle As Long, ByVal dwMilliseconds As Long) As Long


Dim ~Op(1) as string
dim ~OpPos(1) as integer
dim ~OpLen(1) as integer


DEFSTR StartPath$ = COMMAND$(0)-Application.ExeName
DEFSTR StartDir=StartPath$ 'curdir$+"\"


dim DZGini as QINI
DZGini.FileName=StartDir+"DZGini.ini"  '!!! "c:\BAS\RAPIDQ\RQ IDE\RQdb.ini"

defint flParsed=0
childName$=""
ChildType$=""
parentName$=""
parentType$=""

subclr=&H8EAE1A ' &H7B00FF'&H0042FF

ver$="RQFDsg v.2599b Nov 2021"
projectpath$="RQFormDsg projects\"

if direxists(projectpath$)=0 then
  mkdir projectpath$
end if


projectDir$=""

OldPv$="" ' старое значение свойства
defint OldCol=-1,OldRow=-1 ' предыдущая ячейка. При клике на новую ячейку значение из edit переписывается в ячейку

'!!! ----- HiLight -----
Declare Sub HtHLBoxClick
dim HotTAbHL as long
HotTAbHL=1


'!!! ----- цвета подсветки ---
defint HLColor (0 TO 15):  for i=0 to  15 : HLColor(i)=0: next i
HLColor(0)=&HA5E4F5
HLColor(1)=&HFF0000
HLColor(2)=&HFF0082
HLColor(3)=&HFF0000
HLColor(4)=&HFF0000
HLColor(5)=&HFF0000
HLColor(6)=&H00BE00
HLColor(7)=&H0077F9
HLColor(8)=&H0000FF
HLColor(9)=0
HLColor(10)=&HF9E7FF
HLColor(11)=clDBlue
HLColor(12)=&HFFF2F1
HLColor(13)=&HE2ECf8
HLColor(14)=&HE2ECB8




defint center=0


'declare sub bas2
'-- messages
CONST WM_DESTORY = 2
CONST WM_PAINT = &HF

'-- Edit Control Messages

'-- EDITWORDBREAKPROC code values
Public Const WB_LEFT = 0
Public Const WB_RIGHT = 1
Public Const WB_ISDELIMITER = 2

Type Point
  Left As Long
  Top As Long
End Type

'CONST GWL_WNDPROC = (-4)
'CONST GWL_HWNDPARENT = (-8)


dim HiLiteFont as QFont
dim HiLiteFont1 as QFont
HiLiteFont.bold=0
HiLiteFont.Name="FixedSys"

DIM keyList AS QStringList
DIM LineNumList AS QStringList


dim StrFont1 as QFont
StrFont1.name="FixedSys"


dim ObjList as QStringList

IF fileExists("keyword.lst") = 0 THEN
  'PRINT "ERROR can't find file keyword.lst "+"keyword.lst" 'fullPath$+
  showmessage ("2370 ERROR. Can't find file keyword.lst "+"keyword.lst")
  'END
ELSE
  'PRINT "Load file keyword.lst "+"keyword.lst" - загрузка ключевых слов для подсветки
  keyList.LoadFromFile("keyword.lst")
END IF

ss$=keyList.text
defint strptr
strptr=sadd(ss$)



declare sub CmpEditOnKeyUp (Key AS WORD, Shift AS INTEGER)


Declare SUB SetAddedObjProp(parenthWnd AS long,Sender AS QPANEL, otype as string, oIdx as long, oWidth as long, oHeight as long, color as long, border as long, ChildeInPanelType as string)
Declare SUB SaveNewObjDataGrid(hWnd as long, token as string,ObjectIndex as long, oLeft  as long, oTop  as long, oWidth as long,oHeight as long,oColor as long)


declare function HiLight lib "HiLightdllv4.dll" alias "HiLight@16"_
(byval RhWnd as long, byval HiLiteFontHandle as long,  ptrKeyList as long, hthl as long ) as long

'!!! ---- RichEditWndProc -----
declare FUNCTION RichEditWndProc (hWnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG



Declare sub showwin
Declare sub chiudi
declare sub resize
DECLARE SUB TimeUpdate
DECLARE SUB New_Click
DECLARE SUB Open_Click
DECLARE SUB Save_Click
DECLARE SUB SaveAs_Click
DECLARE SUB Compile_Click
DECLARE SUB Run_Click
DECLARE SUB CompOk_Click
DECLARE SUB Print_Click
DECLARE SUB Exit_Click
DECLARE SUB Undo_Click
DECLARE SUB Redo_Click
DECLARE SUB Cut_Click
DECLARE SUB Copy_Click
DECLARE SUB Paste_Click
DECLARE SUB SelectAll_Click
DECLARE SUB Delete_Click
DECLARE SUB Find_Click
DECLARE SUB Replace_Click
DECLARE SUB About_Click
DECLARE SUB Show_Hint (Hint AS String)
DECLARE SUB Capital_Click
DECLARE SUB Upper_Click
DECLARE SUB Lower_Click

DIM OpDialog AS QOPENDIALOG
DIM SvDialog AS QSAVEDIALOG
DIM SaveDialog AS QSAVEDIALOG

defint SrcEditLineCount ' число строк в редакторе
defstr RichRow1,  RichCol1, RichRow2,  RichCol2, RichRow3,  RichCol3
SrcFileName$="Noname.bas"


declare sub SrcEditOnKeyDown (Key AS WORD, Shift AS INTEGER)
declare sub SrcEditOnKeyUp (Key AS WORD, Shift AS INTEGER)
declare sub RichEditOnMouseDown
declare sub  R2Change
declare Sub BuildObjTree
Declare Sub ShowObjects

Declare Sub TabChange

Declare Sub PropertyGridOnKeyPress  (Key AS BYTE)


'!!! ---visual form designer --------------------------
DECLARE SUB PropertyFieldUpdate(pField AS string, vField AS string)


Declare FUNCTION IsParentValid(hWnd AS long) AS integer
Declare Function GetQParent (ParenthWnd  AS long ) as string
Declare FUNCTION IsObjectNonVis(ObjIndex AS integer) AS integer



Declare SUB AddQMenuItem(hWnd AS long)
Declare SUB AddQMainMenu(hWnd AS long)
Declare SUB AddQCHECKBOX(hWnd AS long)
Declare Sub AddQRICHEDIT(hWnd AS long)
Declare Sub AddQLABEL(hWnd AS long)
Declare Sub AddQCOOLBTN(hWnd AS long)

Declare Sub AddQCOMBOBOX(hWnd AS long)
Declare Sub AddQLISTBOX(hWnd AS long)
Declare Sub AddQGROUPBOX(hWnd AS long)
Declare Sub AddQSCROLLBOX(hWnd AS long)
Declare Sub AddQSCROLLBAR(hWnd AS long)
Declare Sub AddQSTRINGGRID(hWnd AS long)
Declare Sub AddQLISTVIEW(hWnd AS long)
Declare Sub AddQDIRTREE(hWnd AS long)
Declare Sub AddQFILELISTBOX(hWnd AS long)
Declare Sub AddQTREEVIEW(hWnd AS long)
Declare Sub AddQOUTLINE(hWnd AS long)
Declare Sub AddQGAUGE(hWnd AS long)
Declare Sub AddQTRACKBAR(hWnd AS long)
Declare Sub AddQHEADER(hWnd AS long)
Declare Sub AddQSTATUSBAR(hWnd AS long)
Declare Sub AddQOLECONTAINER(hWnd AS long)
Declare Sub AddQSPLITTER(hWnd AS long)

Declare SUB AddQCANVAS(hWnd AS long)                                        ' Fudge using QPANEL
Declare SUB AddQImage(hWnd AS long)                                        ' Fudge using QPANEL

Declare Sub AddNonVisible(hWnd AS long)


dim PropList as QStringList




$DEFINE MAX_rqOBJECTS     128 ' max RQ components types supported  including custom components

$DEFINE MAX_OBJECTS     128   ' Limit of components (including forms) can de added
$DEFINE MAX_FORMS       32'16 ' This limit seems reasonable
$DEFINE MAX_MENUS       8     ' Overkill?

$DEFINE NON_VISIBLE     30    ' 0->29 Visible, 30->55 non-visible
$DEFINE MAX_TOOLBTNS    55                                          ' 5 TABs: 15 + 14 + 11 + 4 + 11

$DEFINE MAX_MAINMENU        1
$DEFINE MAX_POPMENU         2

dim StrFont(0 TO MAX_OBJECTS) as qfont


DIM AddedObjectList(0 TO MAX_OBJECTS) AS string      ' Components added (with all properties)...
' ...0=Main form -> Forms(1)

DEFINT NewObjectID=0, NonVisCount
DEFINT  FormIndex, NonVIndex ' ' global index of added Forms, Nonvisual components


DEFINT ObjectIndex,ObjectCount    ' global index of added objects - added from component palette ans added from source parsing
DEFINT OldObjectIndex

FormIndex=0: ObjectIndex=0: ComponentCount=0  '! FormIndex=0 - форма по которой кликнули - selected form
FormCount=0: ObjectCount=0: ComponentCount=0  '! FormCount=0 - количество добавленных форм



DIM ObjectType(0 TO MAX_OBJECTS) AS string       '!!! Component's type ie  QPANEL, QButton etc
DIM ObjTypeIndex(0 TO MAX_OBJECTS) as integer  ' index of an object in the type group ie ObjTypeIndex(ObjIndex)
DIM ObjectHandle(0 TO MAX_OBJECTS) AS long     '!!! Component's handle
DIM ObjectName(0 TO MAX_OBJECTS) AS string     '!!! Component's name  ie Edit1, Panel1, StrinGrid3 etc
dim ObjVisible(0 TO MAX_OBJECTS) AS integer  ' component(ObjectIndex) - visible or nonvisible
dim ObjParentIdx(0 TO MAX_OBJECTS) AS integer  ' ObjectIndex of the parents of the component(ObjectIndex)
'well.. if component(ObjectIndex) has a parent - ObjectIndex of this parent stored in ObjParentIdx(ObjectIndex),so
'handle of the parent of component(ObjectIndex) stored in ObjectHandle(ObjParentIdx(ObjectIndex))

dim ObjectTypeList as QstringList



DIM Forms(0 TO MAX_FORMS) AS QFORM
DIM FormName(0 TO MAX_FORMS) AS string

'DIM DirTree(16) AS QDIRTREE
DIM DirTree0 AS QDIRTREE
DIM DirTree1 AS QDIRTREE
DIM DirTree2 AS QDIRTREE
DIM DirTree3 AS QDIRTREE
DIM DirTree4 AS QDIRTREE
DIM DirTree5 AS QDIRTREE
DIM DirTree6 AS QDIRTREE
DIM DirTree7 AS QDIRTREE

DIM BoxDTree(16) AS QPANEL

DIM TreeView0 AS QTREEVIEW
DIM TreeView1 AS QTREEVIEW
DIM TreeView2 AS QTREEVIEW
DIM TreeView3 AS QTREEVIEW
DIM TreeView4 AS QTREEVIEW
DIM TreeView5 AS QTREEVIEW
DIM TreeView6 AS QTREEVIEW
DIM TreeView7 AS QTREEVIEW

DIM BoxTree(16) AS QPANEL


DIM frmOutLine0 AS QOUTLINE
DIM frmOutLine1 AS QOUTLINE
DIM frmOutLine2 AS QOUTLINE
DIM frmOutLine3 AS QOUTLINE
DIM frmOutLine4 AS QOUTLINE
DIM frmOutLine5 AS QOUTLINE
DIM frmOutLine6 AS QOUTLINE
DIM frmOutLine7 AS QOUTLINE

DIM BoxOutLine(16) AS QPANEL

dim MainMnu0 AS QMAINMENU
dim MainMnu1 AS QMAINMENU
dim MainMnu2 AS QMAINMENU
dim MainMnu3 AS QMAINMENU
dim MainMnu4 AS QMAINMENU
dim MainMnu5 AS QMAINMENU
dim MainMnu6 AS QMAINMENU
dim MainMnu7 AS QMAINMENU
dim MainMnu8 AS QMAINMENU
dim MainMnu9 AS QMAINMENU
dim MainMnu10 AS QMAINMENU
dim MainMnu11 AS QMAINMENU
dim MainMnu12 AS QMAINMENU
dim MainMnu13 AS QMAINMENU
dim MainMnu14 AS QMAINMENU
dim MainMnu15 AS QMAINMENU

dim MnuItem(256) AS QMenuItem
DEFINT MainMnuIdx
defint MnuItemIdx

Dim BoxEdit(1) AS QPANEL
DIM BoxRich(1) AS QPANEL
DIM BoxLabel(1) AS QPANEL
'DIM BoxLabel(1) AS QLabel

DIM boxBut(1) AS QPANEL                                   ' Fudge using QPANEL
DIM BoxCool(1) AS QPANEL

DIM BoxTab(1) AS QPANEL                                ' QPanel as a container
DIM TabCtrl(1) AS QTABCONTROL

DIM panelOval(1) AS QPANEL
DIM Ovalb(32) AS QOVALBTN

DIM Check(32) AS QCHECKBOX
DIM Radio(32) AS QRADIOBUTTON
DIM dPan(32) AS QPANEL

DIM Combo(32) AS QCOMBOBOX
DIM CPan(1) AS QPANEL

DIM ListB(32) AS QLISTBOX
DIM GrpBox(32) AS QGROUPBOX
DIM ScrollB(32) AS QSCROLLBOX
DIM BoxInner(32) AS QPANEL                              ' For effect - force scrollbars visible
DIM ScrollBar(32) AS QSCROLLBAR
DIM StrGrid(32) AS QLISTVIEW

DIM ListView(32) AS QLISTVIEW
DIM Headr(32) AS QHEADER
DIM BoxHeadr(32) AS QPANEL
DIM StatBar(32) AS QSTATUSBAR
DIM BoxStat(32) AS QPANEL

DIM dFileL(32) AS QFILELISTBOX
DIM BoxFile(32) AS QPANEL
DIM dGauge(32) AS QGAUGE
DIM panGauge(32) AS QPANEL

DIM dTrackBar(32) AS QTRACKBAR
DIM panSplit(32) AS QPANEL
DIM oleContainer(32) AS QPANEL

DIM Canv(32) AS QCanvas
DIM panCanv(32) AS QPANEL

DIM Imag(32) AS QImage
DIM panImage(32) AS QPANEL

DIM Carets(1 TO 8) AS QPANEL                                        ' Carets used in moving/resizing objects
DEFINT ActiveCaret, ReSizing                                        ' Resizing an object

DIM CaretsTimer AS QTIMER                                           ' Keeps carets() "on top"
DIM ScanTimer AS QTIMER                                                  ' Main timer for visual editing
DIM DelayTimer AS QTIMER                                            ' One-shot timer used with input file or clipboard

DIM ColorPick AS QColorDlg                                          ' MY temp version (see RapidFRM.inc)
'DIM ColorPick AS QColorDialog

DEFINT MouseSaveX, MouseSaveY                                       ' Needed by copy/paste with QPopupMenus

' Visible components ItemCounts - ie Last added component
DEFINT EdCount=1, RichCount=1, LabelCount=1, ButnCount=1, CoolCount=1
DEFINT CheckCount=1, RadioCount=1, ComboCount=1, ListBCount=1, PanCount=1, GrpBoxCount=1
DEFINT TabContCount=1, ScrollBCount=1, ScrllBarCount=1, StringGCount=1, ListVCount=1
DEFINT HeadCount=1, SplitCount=1, StatCount=1, GlassCount=1, GaugeCount=1, TrackBCount=1
DEFINT OutLnCount=1, DirTCount=1, FileLCount=1, TreeVCount=1, OLEContCount=1, QOVALCount=1


' Non-visible components ItemCounts - ie Last added component
DEFINT ImageCount=1, ImgListCount=1, CanvasCount=1, OleObjCount=1
DEFINT TimerCount=1, SockCount=1, FStreamCount=1, MStreamCount=1, FontCount=1, SQLCount=1
DEFINT BmpCount=1, RegCount=1, StrListCount=1
' Dialog components
DEFINT OpenDlgCount=1, SaveDlgCount=1, FontDlgCount=1, ColorDlgCount=1
' DirectX components
DEFINT DXScreenCount=1,DXImgListCount=1,DXTimerCount=1,DXSoundCount=1,D3DFaceCount=1
DEFINT MeshBuilderCount=1,D3DFrameCount=1,D3DLightCount=1,TextureCount=1,VectorCount=1,D3DWrapCount=1
' Menu indices
DEFINT MainMenuCount=1, PopUpCount=1

' Visible components indices (QOvalBtn done differently - see RapidFRM.inc)
DEFINT EdIndex, RichIndex, LabelIndex, ButnIndex, CoolIndex
DEFINT CheckIndex, RadioIndex, ComboIndex, ListBIndex, PanIndex, GrpBoxIndex
DEFINT TabContIndex, ScrollBIndex, ScrllBarIndex, StringGIndex, ListVIndex
DEFINT HeadIndex, SplitIndex, StatIndex, GlassIndex, GaugeIndex, TrackBIndex
DEFINT OutLnIndex, DirTIndex, FileLIndex, TreeVIndex, OLEContIndex, QOVALIndex


' Non-visible components indices
DEFINT ImageIndex, ImgListIndex, CanvasIndex, OleObjIndex
DEFINT TimerIndex, SockIndex, FStreamIndex, MStreamIndex, FontIndex, SQLIndex
DEFINT BmpIndex, RegIndex, StrListIndex
' Dialog components
DEFINT OpenDlgIndex, SaveDlgIndex, FontDlgIndex, ColorDlgIndex
' DirectX components
DEFINT DXScreenIdx,DXImgListIdx,DXTimerIdx,DXSoundIdx,D3DFaceIdx
DEFINT MeshBuilderIdx,D3DFrameIdx,D3DLightIdx,TextureIdx,VectorIdx,D3DWrapIdx
' Menu indices
DEFINT MainMenuIndex, PopUpIndex


' MainMenu & PopupMenu Editing
DECLARE SUB MenuEditor
DECLARE SUB AddMainMenu
DECLARE SUB AddPopupMenu
DECLARE SUB UpdateProjectMenu
DECLARE SUB ParentChange
DECLARE SUB OptionChange
' Adding new components
DECLARE SUB AddNewObject (parenthWnd  AS integer)
DECLARE SUB AddNewForm
DECLARE FUNCTION GetDefaultProperties(ComponentID AS integer) AS string


'!!! --- end visual form designer --------------------------


DECLARE SUB RefreshObject(hWnd AS long, nuRect AS QRECT)
'Declare SUB SetAddedObjProp(parenthWnd AS long,Sender AS QPANEL, otype as string, oIdx as long, oWidth as long, oHeight as long, color as long, border as long, ChildeInPanelType as string)
Declare SUB SaveNewObjDataGrid(hWnd as long, token as string,ObjectIndex as long, oLeft  as long, oTop  as long, oWidth as long,oHeight as long,oColor as long)
Declare Sub cmboxObjOnChange

'------------------- Forward Declarations ---------------------------------------------
DECLARE FUNCTION WaitOnHelp LIB "kernel32" ALIAS "WaitForSingleObject" (hHandle AS long, _
                                                                        dwMilliseconds AS long) AS long


Declare Sub GlobalGridondrawcell(Col&, Row&, State%, Rect AS QRect, Sender as QStringgrid)
Declare Sub GlobalGridselectcell(Col&, Row&, CanSelect%, Sender as QStringgrid)
Declare Sub HideFormsBtnOnClick

declare FUNCTION StringGridWndProc (hWnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG



'DECLARE FUNCTION SetWindowLongAPI LIB "user32" ALIAS "SetWindowLongA" _
'(ByVal hWnd AS LONG, ByVal nIndex AS LONG, ByVal dwNewLong AS LONG) AS LONG


' General stuff
DECLARE sub SetFIELD(Source$,delim$,fnum%,updField$)

DECLARE SUB ForceSelection(hWnd AS long)

DECLARE SUB Initialise
DECLARE FUNCTION GetScreenHeight() AS integer
DECLARE SUB FormPopUp(X AS integer, Y AS integer)
DECLARE SUB ObjPopUp(X AS integer, Y AS integer)
DECLARE SUB NonVisPopup(X AS integer, Y AS integer)
DECLARE SUB DesignTabChange                                         ' Active design window
DECLARE SUB SelectComboChange                                       ' Component selection combo
DECLARE SUB ObjInspectorTabChange                                      ' Component properties/methods/events
DECLARE SUB MainClose(Action AS integer)
DECLARE SUB NoClose(Action AS integer)
DECLARE SUB HelpBtnClick
DECLARE FUNCTION FindHelpFile() AS integer
DECLARE SUB ProgramEnd
' Project file import/export
DECLARE SUB LoadProject                                             ' Load & parse the project file/clipboard
DECLARE SUB SaveAsOnClick        '' SaveAs item clicked

DECLARE SUB ShowProject                                             ' Display project data
DECLARE SUB BuildFormCode                                           ' Output RapidQ code (Default)
DECLARE SUB BuildFBCode                                             ' Output FreeBasic code
' Button stuff
DECLARE SUB LoadSingleButtons                                       ' Additional separate buttons
DECLARE SUB LoadToolbarHints                                        ' 'TAB'ed Toolbar buttons
DECLARE SUB ButnCmd(idx AS integer)
DECLARE SUB ToolTabChange
DECLARE SUB AboutClick
DECLARE SUB Deselect
' PopUp menu options
DECLARE SUB HelpOnObject
DECLARE SUB AlignObject                                             ' Visual editing options
DECLARE SUB MouseCopyObject                                         ' ditto
DECLARE SUB MousePasteObject                                        ' ditto
DECLARE SUB DeleteComponent                                            ' ditto
DECLARE SUB CopyToClipBrd                                           ' STAND_ALONE mode options
DECLARE SUB SelectionToClipBrd                                      ' ditto
DECLARE SUB SaveTemplate                                            ' FreeBASIC save RQ template file
DECLARE SUB SaveFile                                                ' ditto
DECLARE SUB AskExit
DECLARE SUB ExitNoUpdate                                            ' ditto
DECLARE SUB SaveAndExit                                             ' Existing Project option
DECLARE SUB FB_SaveAndExit                                          ' FreeBasic save to clipboard
' Forms() - ALL forms in the array
DECLARE SUB FormsOnMouseMove(X AS long, Y AS long, Shift AS long, Sender AS QFORM)
DECLARE SUB ReSizeForm(Sender AS QFORM)
DECLARE SUB ReSizeForm_OLD(Sender AS QFORM)

DECLARE SUB PaintFormGrid(Sender AS QFORM)
' Caret manipulation
DECLARE SUB CaretMseDown(MouseButton AS long, X AS long, Y AS long, Shift AS long, Sender AS QPANEL)
DECLARE SUB CaretMseUp(MouseButton AS long, X AS long, Y AS long, Shift AS long, Sender AS QPANEL)
DECLARE SUB CaretsOnTop
DECLARE SUB ShowCarets(tgtRect AS QRECT)
DECLARE SUB HideCarets
' Object - Mouse editing
DECLARE SUB ScanMouse
DECLARE SUB MouseResizeObject(hWnd AS long)
DECLARE SUB MouseMoveObject(hWnd AS long)
DECLARE FUNCTION HandleToIndex(hWnd AS long) AS integer
' Object - Grid editing
DECLARE SUB UpdatePropGrid(idx AS integer)
DECLARE SUB EditPropertyField(Col AS integer, Row AS integer, CanSelect AS integer, Sender AS QSTRINGGRID)
DECLARE SUB EditMethodField(Col AS integer, Row AS integer, CanSelect AS integer, Sender AS QSTRINGGRID)
DECLARE SUB EditEventField(Col AS integer, Row AS integer, CanSelect AS integer, Sender AS QSTRINGGRID)
DECLARE SUB FieldUpdateCombo(Sender AS QCOMBOBOX)
DECLARE SUB FieldUpdateEdit(Key AS word, Shift AS integer, Sender AS QEDIT)
DECLARE SUB ReDrawComponent ' обновление при перемещении
DECLARE SUB ReDrawComponentbyField ' обновление при изменении свойства

DECLARE SUB HideEditCtls(Col AS integer, Row AS integer, State AS integer, Rect AS QRect, Sender AS QSTRINGGRID)
Declare Sub PropertyGridOnDrawCell(Col% AS INTEGER, Row% AS INTEGER, State AS INTEGER, Rect AS QRECT)

' Set component properties
DECLARE sub PropertyValueUpdate
DECLARE function GetPropValue (prop as string) as integer
DECLARE function GetPropString (prop as string) as string


' MainMenu & PopupMenu Editing
DECLARE SUB MenuEditor
DECLARE SUB AddMainMenu
DECLARE SUB AddPopupMenu
DECLARE SUB UpdateProjectMenu
DECLARE SUB ParentChange
DECLARE SUB OptionChange
' Adding new components
'DECLARE SUB AddNewObject
'DECLARE SUB AddNewForm
'DECLARE FUNCTION GetDefaultProperties(ComponentID AS integer) AS string

'DECLARE FUNCTION TRIM$(inpString AS string) AS string

'---------------------------- Globals -------------------------------------------------------
' General vars
DIM OpenDialog AS QOpenDialog
'DIM OpenDialog AS QFILEDIALOG
OpenDialog.FileName=""
OpenDialog.Filter ="Bas Files  *.bas;*.rqb;*.vbs|*.bas;*.rqb;*.vbs|_
Ini Files *.ini;*.prj|*.ini;*.prj|_
Inс Files *.inc;*tpl|*.inc;*tpl|_
Log Files *.log|*.log|_
Txt Files *.txt|*.txt|_
Html Files *.*htm*;*.js;*.vbs;*.css|*.*htm*;*.js;*.vbs;*.css|_
Graphics Files *.ico;*.bmp|*.ico;*.bmp|_
Media Files *.*wav;*.mid;*.mp3|*.*wav;*.mid;*.mp3|_
All Files *.*|*.*|" '_
OpenDialog.FilterIndex = 1

'DIM SaveDialog AS QSaveDialog



DEFINT ProjectMode                           ' New, existing project file or clipboard
DEFINT ErrorCondition                        ' Error True/False flag
'DEFINT ComponentCount                       ' Counter for save/exit action

DEFSTR RQHelpFile                                                   ' Full path to Rapidq.chm
DEFSTR ProjectFile                                                  ' Filename parameter input - existing project
DIM ProjectStream AS QMEMORYSTREAM                                  ' Holds a Project file/clipboard text if needed
DIM ComponentRef AS QMEMORYSTREAM                                   ' Stream to hold component default properties
DIM HelpRef AS QMEMORYSTREAM                                        ' Contains the help text

DIM FB_InputList AS QSTRINGLIST

'dim StrFont(0 TO MAX_OBJECTS) as qfont

dim RQ2incList as qstringlist
dim PropertyList as qstringlist
defint pidx

defstr PropValueS

'defint rowi, ci
'defstr celli
'defstr const_i



' Vars for parsing CREATE .. END CREATE blocks of code
DEFINT StartOfBlocks, EndOfBlocks                                   ' Markers in Project file/clipboard text
DEFSTR FormsList                                                    ' List of Forms to display
DEFSTR KnownsList                                                   ' List of objects outside of forms (known parents)
DEFSTR MainMenuList                                                 ' List of QMAINMENU components found
DEFSTR PopMenuList                                                  ' List of QPOPUPMENU components found
DEFSTR UnknownList                                                  ' List of "unknown" components found eg ...Ex types
DEFSTR FwdDeclares                                                  ' New component events list
DEFSTR ExistDeclares                                                ' Existing declares if input file or clipboard
DEFSTR MenuUpdateStr

DIM FontDialog AS QFontDialog
FontDialog.name="Arial"


' Vars for visual display
DIM btn AS QBUTTON

'DIM AddedObjectList(0 TO MAX_OBJECTS) AS string                          ' Components added (with all properties)...
' ...0=Main form -> Forms(1)

'DIM ObjectType(0 TO MAX_OBJECTS) AS string                          '!!! Component's types  QPANEL, QButton etc
'DIM ObjTypeIndex(0 TO MAX_OBJECTS) as integer                       ' index of an object in the type group ie ObjTypeIndex(ObjIndex)



'DIM Forms(1 TO MAX_FORMS) AS QFORM
DEFINT ThemeOffsetY                                                 ' Active TitleBar height adjustment

DEFSTR ToolbarHint                                                  ' Hints for all Toolbar buttons
DIM xtraBtns(0 TO 3) AS QCOOLBTN                                    ' 4 Additional single buttons
DIM NonVisBMP AS QBITMAP                                            ' "Non-visibles" temp bmp


'Dim BoxEdit(1) AS QPANEL
'DIM BoxRich(1) AS QPANEL
'DIM BoxLabel(1) AS QPANEL
'DIM boxBut(1) AS QPANEL                                   ' Fudge using QPANEL
'DIM BoxCool(1) AS QPANEL                                  ' Fudge using QPANEL
'DIM BoxTab(1) AS QPANEL                                ' QPanel as a container
'DIM TabCtrl(1) AS QTABCONTROL

'DIM panOval(1) AS QPANEL
'DIM imgOval(1) AS QCANVAS
'DIM Check(1) AS QCHECKBOX
'DIM Radio(1) AS QRADIOBUTTON
'DIM dPan(1) AS QPANEL
'DIM Combo(1) AS QCOMBOBOX
'DIM ListB(1) AS QLISTBOX
'DIM GrpBox(1) AS QGROUPBOX
'DIM ScrollB(1) AS QSCROLLBOX
'DIM BoxInner(1) AS QPANEL                              ' For effect - force scrollbars visible
'DIM ScrollBar(1) AS QSCROLLBAR
'DIM StrGrid(1) AS QLISTVIEW
'DIM ListView(1) AS QLISTVIEW
'DIM Headr(1) AS QHEADER
'DIM BoxHeadr(1) AS QPANEL
'DIM StatBar(1) AS QSTATUSBAR
'DIM BoxStat(1) AS QPANEL
'DIM dFileL(1) AS QFILELISTBOX
'DIM BoxFile(1) AS QPANEL
'DIM dGauge(1) AS QGAUGE
'DIM panGauge(1) AS QPANEL
'DIM dTrackBar(1) AS QTRACKBAR
'DIM panSplit(1) AS QPANEL
'DIM oleContainer(1) AS QPANEL
'DIM panCanv(1) AS QPANEL
'DIM panImage(1) AS QPANEL

dim tmpRichEdit as QRichEdit






'DIM Carets(1 TO 8) AS QPANEL                                        ' Carets used in moving/resizing objects
'DEFINT ActiveCaret, ReSizing                                        ' Resizing an object
'DIM CaretsTimer AS QTIMER                                           ' Keeps carets() "on top"

'DIM ScanTimer AS QTIMER                                                  ' Main timer for visual editing
'DIM DelayTimer AS QTIMER                                            ' One-shot timer used with input file or clipboard

'DIM ColorPick AS QColorDlg                                          ' MY temp version (see RapidFRM.inc)
'DIM ColorPick AS QColorDialog

'DEFINT MouseSaveX, MouseSaveY                                       ' Needed by copy/paste with QPopupMenus

DEFINT CurrentObject, CurrentForm                                   ' Currently active components
'DEFINT NewObjectID, NonVisCount

' FB stuff
TYPE OBJ_STRUC
  FBLineNum AS integer                                            ' Line # in InList
  FBObjID AS integer                                              ' 0=QFORM, 1=QEDIT etc
  FBObjType AS string*16                                          ' "QFORM" etc
  FBObjName AS string*16                                          ' "Form1" etc
  FBObjPtrName AS string*16                                       ' "lpForm1" etc
  FBObjHandle AS long
  FBObjParent AS long
  FBChildCount AS integer
END TYPE
DIM FB_Objects(0 TO MAX_OBJECTS) AS OBJ_STRUC
DEFINT ObjCount=0
'
'DEFINT ObjectIndex, FrmIndex, NonVIndex

' Visible components indices (QOvalBtn done differently - see RapidFRM.inc)
'DEFINT EdIndex, RichIndex, LabelIndex, ButnIndex, CoolIndex
'DEFINT CheckIndex, RadioIndex, ComboIndex, ListBIndex, PanIndex, GrpBoxIndex
'DEFINT TabContIndex, ScrollBIndex, ScrllBarIndex, StringGIndex, ListVIndex
'DEFINT HeadIndex, SplitIndex, StatIndex, GlassIndex, GaugeIndex, TrackBIndex
'DEFINT OutLnIndex, DirTIndex, FileLIndex, TreeVIndex, OLEContIndex

' Non-visible components indices
'DEFINT ImageIndex, ImgListIndex, CanvasIndex, OleObjIndex
'DEFINT TimerIndex, SockIndex, FStreamIndex, MStreamIndex, FontIndex, SQLIndex
'DEFINT BmpIndex, RegIndex, StrListIndex
' Dialog components
'DEFINT OpenDlgIndex, SaveDlgIndex, FontDlgIndex, ColorDlgIndex
' DirectX components
'DEFINT DXScreenIdx,DXImgListIdx,DXTimerIdx,DXSoundIdx,D3DFaceIdx
'DEFINT MeshBuilderIdx,D3DFrameIdx,D3DLightIdx,TextureIdx,VectorIdx,D3DWrapIdx
' Menu indices
'DEFINT MainMenuIndex, PopUpIndex

DIM fDialog AS QFileDialog

'------------------------------------ Main form -------------------------------------------
CREATE designMenu AS QPOPUPMENU
  CREATE mnuAlign AS QMENUITEM
    Caption="Align to Grid"
    OnClick=AlignObject
  END CREATE
  CREATE mnuCopy AS QMENUITEM
    Caption="Copy Component"
    OnClick=MouseCopyObject
  END CREATE
  CREATE mnuPaste AS QMENUITEM
    Caption="Paste Component"
    OnClick=MousePasteObject
  END CREATE
  CREATE mnuSep1 AS QMENUITEM
    Caption="-"
  END CREATE
  CREATE mnuDelete AS QMENUITEM
    Caption="Delete Component"
    OnClick=DeleteComponent
  END CREATE
  CREATE mnuSep2 AS QMENUITEM
    Caption="-"
  END CREATE
  CREATE mnuHelp AS QMENUITEM
    Caption="Help on Component"
    Enabled=False
    OnClick=HelpOnObject
  END CREATE
  CREATE mnuSep3 AS QMENUITEM
    Caption="-"
  END CREATE
  CREATE mnuQuit AS QMENUITEM
    Caption="Exit Designer"
    OnClick=AskExit
  END CREATE
END CREATE

CREATE codeMenu AS QPOPUPMENU
  CREATE edCopy AS QMENUITEM                                      ' Stand-alone version option
    Caption="Copy all to clipboard"
    OnClick=CopyToClipBrd
  END CREATE
  CREATE partCopy AS QMENUITEM                                    ' Stand-alone version
    Caption="Copy selection to clipboard"
    OnClick=SelectionToClipBrd
  END CREATE
  CREATE mnuSep4 AS QMENUITEM
    Caption="-"
  END CREATE
  CREATE tplSave AS QMENUITEM                                     ' FB all versions save as RQ src file
    Caption="Save FB template file"
    OnClick=SaveTemplate
  END CREATE
  CREATE edSave AS QMENUITEM                                      ' Stand-alone version
    Caption="Save to File"
    OnClick=SaveFile
  END CREATE
  CREATE mnuSep5 AS QMENUITEM
    Caption="-"
  END CREATE
  CREATE edPsave AS QMENUITEM                                     ' Project version option
    Caption="Save Project && Exit"
    OnClick=SaveAndExit
  END CREATE
  CREATE mnuSep6 AS QMENUITEM
    Caption="-"
  END CREATE
  CREATE edQuit AS QMENUITEM
    Caption="Exit Designer Without Changes"
    OnClick=ExitNoUpdate
  END CREATE
END CREATE

CREATE MainForm AS QFORM
  Width=Screen.Width
  Height=GetScreenHeight()                      'Screen.Height-28    ' GetSystemMetrics(SM_CYFULLSCREEN)?
  Left=0
  Top=0
  Caption="RapidFRM "+VER
  'BorderStyle=bsSingle
  OnShow=Initialise
  OnClose=MainClose
  color=clLA

  CREATE MainMnu AS QMAINMENU
    'Parent = CodeEdit
    CREATE mnuFile AS QMENUITEM
      Caption = "&File"
      Checked = 0
      Enabled = 1
      Visible = 1
      CREATE mnuNew AS QMENUITEM
        Caption = "&New"
        Checked = 0
        Enabled = 1
        Hint = "New Document"
        OnClick = new_Click
        Visible = 1
        ShortCut = "CTRL+N"
      END CREATE
      CREATE mnuOpen AS QMENUITEM
        Caption = "&Open"
        Checked = 0
        Enabled = 1
        Hint = "Open Document"
        OnClick = Open_Click
        Visible = 1
        ShortCut = "CTRL+O"
      END CREATE
      CREATE mnuSave AS QMENUITEM
        Caption = "&Save"
        Checked = 0
        Enabled = 1
        Hint = "Save document"
        OnClick = Save_Click
        Visible = 1
        ShortCut = "CTRL+S"
      END CREATE
      CREATE mnuSaveAs AS QMENUITEM
        Caption = "SaveAs"
        Checked = 0
        Enabled = 1
        Hint = "Save document with prompt"
        OnClick = SaveAsOnClick
        Visible = 1
      END CREATE
      CREATE mnuPrint AS QMENUITEM
        Caption = "&Print"
        Checked = 0
        Enabled = 1
        Hint = "Print the current document"
        OnClick = Print_Click
        Visible = 1
        ShortCut = "CTRL+P"
      END CREATE
      CREATE mnuExit AS QMENUITEM
        Caption = "&Exit"
        Checked = 0
        Enabled = 1
        Hint = "Exit the program"
        OnClick = Exit_Click
        Visible = 1
        ShortCut = "ALT+F4"
      END CREATE
    END CREATE
    CREATE mnuEdit AS QMENUITEM
      Caption = "&Edit"
      Checked = 0
      Enabled = 1
      Visible = 1
      CREATE mnuUndo AS QMENUITEM
        Caption = "&Undo"
        Checked = 0
        Enabled = 1
        Hint = "Undo last modification"
        OnClick = Undo_Click
        Visible = 1
        ShortCut = "CTRL+Z"
      END CREATE
      CREATE mnuRedo AS QMENUITEM
        Caption = "&Redo"
        Checked = 0
        Enabled = 1
        Hint = "Revert Undo actions"
        OnClick = Redo_Click
        Visible = 1
      END CREATE
      CREATE EditBar0 AS QMENUITEM
        Caption = "-"
        Checked = 0
        Enabled = 1
        Visible = 1
      END CREATE
      CREATE mnuCut AS QMENUITEM
        Caption = "&Cut"
        Checked = 0
        Enabled = 1
        Hint = "Cut selected text"
        OnClick = Cut_Click
        Visible = 1
        ShortCut = "CTRL+X"
      END CREATE
      CREATE mnuCopy1 AS QMENUITEM
        Caption = "C&opy"
        Checked = 0
        Enabled = 1
        Hint = "Copy selected text"
        OnClick = Copy_Click
        Visible = 1
        ShortCut = "CTRL+C"
      END CREATE
      CREATE mnuPaste1 AS QMENUITEM
        Caption = "&Paste"
        Checked = 0
        Enabled = 1
        Hint = "Paste text"
        OnClick = Paste_Click
        Visible = 1
        ShortCut = "CTRL+V"
      END CREATE
      CREATE EditBar1 AS QMENUITEM
        Caption = "-"
        Checked = 0
        Enabled = 1
        Visible = 1
      END CREATE
      CREATE mnuSelectAll AS QMENUITEM
        Caption = "&SelectAll"
        Checked = 0
        Enabled = 1
        Hint = "Select all text"
        OnClick = SelectAll_Click
        Visible = 1
        ShortCut = "CTRL+A"
      END CREATE
      CREATE mnuDelete1 AS QMENUITEM
        Caption = "&Delete"
        Checked = 0
        Enabled = 1
        Hint = "Delete selected text"
        OnClick = Delete_Click
        Visible = 1
        'ShortCut = "DEL"
      END CREATE
      CREATE EditBar2 AS QMENUITEM
        Caption = "-"
        Checked = 0
        Enabled = 1
        Visible = 1
      END CREATE
      CREATE mnuLower AS QMENUITEM
        Caption = "&Lower Case"
        Checked = 0
        Enabled = 1
        Hint = "Convert to Lower"
        OnClick = Lower_Click
        Visible = 1
      END CREATE
      CREATE mnuUpper AS QMENUITEM
        Caption = "&Upper Case"
        Checked = 0
        Enabled = 1
        Hint = "Convert to Upper"
        OnClick = Upper_Click
        Visible = 1
      END CREATE
      CREATE mnuCapitalize AS QMENUITEM
        Caption = "Capitalize"
        Checked = 0
        Enabled = 1
        Hint = "Capitalize"
        OnClick = Capital_Click
        Visible = 1
      END CREATE
    END CREATE
    CREATE mnuFind AS QMENUITEM
      Caption = "Find/&Replace"
      Checked = 0
      Enabled = 1
      Visible = 1
      CREATE mnuFindit AS QMENUITEM
        Caption = "&Find"
        Checked = 0
        Enabled = 1
        Hint = "Find text"
        OnClick = Find_Click
        Visible = 1
        ShortCut = "CTRL+F"
      END CREATE
      CREATE mnuReplace AS QMENUITEM
        Caption = "&Replace"
        Checked = 0
        Enabled = 1
        Hint = "Find and Replace text"
        OnClick = Replace_Click
        Visible = 1
        ShortCut = "CTRL+R"
      END CREATE
    END CREATE
    CREATE mnuCompile AS QMENUITEM
      Caption = "&Compile"
      Checked = 0
      Enabled = 1
      Visible = 1
      CREATE mnuCompileit AS QMENUITEM
        Caption = "&Compile"
        Checked = 0
        Enabled = 1
        Hint = "Compile"
        OnClick = Compile_Click
        Visible = 1
        ShortCut = "F5"
      END CREATE
      CREATE mnuRun AS QMENUITEM
        Caption = "Compile and &Run"
        Checked = 0
        Enabled = 1
        Hint = "Compile and Run"
        OnClick = Run_Click
        Visible = 1
        ShortCut = "CTRL+F5"
      END CREATE
    END CREATE
    CREATE mnuAbout AS QMENUITEM
      Caption = "&About"
      Checked = 0
      Enabled = 1
      Hint = "About CodeEdit"
      OnClick = About_Click
      Visible = 1
    END CREATE



  END CREATE


  CREATE stat AS QSTATUSBAR
    SizeGrip=False
    AddPanels "", "", "", "", ""
    Panel(0).Width=MainForm.ClientWidth\2
    Panel(1).Width=MainForm.ClientWidth\12
    Panel(2).Width=MainForm.ClientWidth\12
    Panel(3).Width=MainForm.ClientWidth\12
  END CREATE

  create  StatusBar AS QSTATUSBAREX ' QStatusBar
    AddPanels "Row ", "Col ", "Pos ","Asc ", "EOL ",""
    Panel(0).Width = 100
    Panel(1).Width = 60
    Panel(2).Width = 110
    Panel(3).Width = 45
    Panel(4).Width = 100
    'Panel(4).Width = 135
    Panel(5).Width = 100
    'Panel(0).Alignment = taCenter
    'AddOptPanel PanelSt,5
  END CREATE

  create  StBarFrmDsg AS QSTATUSBAREX 'QStatusBar
    AddPanels "", "", "", "", "", "", ""
    Panel(0).Width = 100:Panel(0).Caption="Pan0"
    Panel(1).Width = 100:Panel(1).Caption="Pan1"
    Panel(2).Width = 100:Panel(2).Caption="Pan2"
    Panel(3).Width = 100  :Panel(3).Caption="Pan3"
    Panel(4).Width = 150  :Panel(4).Caption="Pan4"
    'Panel(4).color = clo
    'Panel(4).Width = 135
    Panel(5).Width = 150:Panel(5).Caption="Pan5"

    SizeGrip=False
    'color=cla

  END CREATE


  CREATE ToolBox AS QPANEL
    'Width=MainForm.ClientWidth
    Height=60
    Align=alTop
    Caption=""
    CREATE HideFormsBtn AS QBUTTON
      Caption = "Hide Forms"
      Left = 605
      Top = 20
      width=70
      OnClick=HideFormsBtnOnClick
    END CREATE

    CREATE ToolBarTab AS QTABCONTROL
      Width=445                                               ' 15*29+10 - 15 btns plus
      Height=54
      Left=5
      Top=2
      Tabheight=16
      TabWidth=87                                             ' 15*29\5 - 5 tabs
      TabInactiveColor=&hbfbfbf
      Font.Size=8
      Font.Color=&h1f1fbf
      Addtabs "Standard","Additional","Non-visible","Dialogs","DirectX"
      OnChange=ToolTabChange
      CREATE ToolBar1 AS QToolBarEX
        BtnCount=15
        Cursor=crHandPoint
        Tag=1                                               ' Button # of first button
        BMPHandle=3                                         ' Resource(3)
        OnSelect=ButnCmd
      END CREATE
      CREATE ToolBar2 AS QToolBarEX
        BtnCount=14
        Cursor=crHandPoint
        Tag=16                                              ' Button # of first button
        Visible=False
        BMPHandle=4                                         ' Resource(4)
        OnSelect=ButnCmd
      END CREATE
      CREATE ToolBar3 AS QToolBarEX
        BtnCount=11
        Cursor=crHandPoint
        Tag=30                                              ' Button # of first button
        Visible=False
        BMPHandle=5                                         ' Resource(5)
        OnSelect=ButnCmd
      END CREATE
      CREATE ToolBar4 AS QToolBarEX
        BtnCount=4
        Cursor=crHandPoint
        Tag=41                                              ' Button # of first button
        Visible=False
        BMPHandle=6                                         ' Resource(6)
        OnSelect=ButnCmd
      END CREATE
      CREATE ToolBar5 AS QToolBarEX
        BtnCount=11
        Cursor=crHandPoint
        Tag=45                                              ' Button # of first button
        Visible=False
        BMPHandle=7                                         ' Resource(7)
        OnSelect=ButnCmd
      END CREATE
    END CREATE
    CREATE NonVisPanel AS QGROUPBOX                             ' Container for non-visible components
      Left=450+8*30                                           ' Toolbar tabs + 4 * buttons + 2 * button gap
      Top=5
      Width=400 'ToolBox.Width-NonVisPanel.Left-45
      Height=50
      Caption="Project non-visible components"
    END CREATE
  END CREATE


  CREATE ObjInspectorPan AS QPANEL '===========================
    'color=clo
    align=alclient

    'Left=DesignPan.Width
    'Top=DesignPan.Top
    'Width=Screen.Width-DesignPan.Width
    'Height=DesignPan.ClientHeight
    CREATE SelectionCombo AS QCOMBOBOX
      Align=alTop
      Height=24
      'Width=ObjInspectorPan.ClientWidth-4
      Style=csDropDownList
      OnChange=SelectComboChange
    END CREATE
    CREATE ObjInspectorTab AS QTABCONTROL
      Align=alClient
      AddTabs "Properties","Events"',"Methods"',"Global"
      OnChange=ObjInspectorTabChange
      'color=clr


      CREATE cmboxObj AS QCOMBOBOX
        Text = ""
        Left = 1
        Top = 1
        TabOrder = 8
        align=altop
        OnChange=cmboxObjOnChange
      END CREATE

      CREATE ObjNameGrid AS QSTRINGGRID                      ' Properties of selected component
        Top = 3
        Align=alTop
        RowCount=2
        DefaultRowHeight=16
        height=38
        FixedRows=1
        FixedCols=0
        ColCount=6
        Separator=chr$(09)
        color=&&&H81FFFF
        ColWidths(0)=100
        ColWidths(1)=100'ObjInspectorTab.ClientWidth-120
        ColWidths(2)=100'ObjInspectorTab.ClientWidth-120
        ColumnStyle(0)=gcsNone
        ColumnStyle(1)=gcsNone
        AddOptions=goThumbTracking, goDrawFocusSelected, goColSizing,  goEditing

        Cell(0,0)="Object Name"
        Cell(1,0)="Object Type"
        Cell(2,0)="Parent"
        ScrollBars=0'ssVertical
        'OnSelectCell=EditPropertyField
        'OnDrawCell=HideEditCtls
      END CREATE
      CREATE PropertyListGrid AS QSTRINGGRID                      ' Properties of selected component
        Align=altop 'Client
        height=138
        RowCount=2
        color=cllb
        DefaultRowHeight=16
        FixedRows=1
        FixedCols=1
        ColCount=6
        Separator=chr$(09)
        visible=1
        ScrollBars=ssBoth'Vertical

      END CREATE

      CREATE PropertyGrid AS QSTRINGGRID                      ' Properties of selected component
        Align=alClient
        RowCount=10
        DefaultRowHeight=16
        FixedRows=1
        FixedCols=1
        ColCount=6
        Separator=chr$(09)
        color=&HF0ECBD
        ColWidths(0)=100
        ColWidths(1)=100'ObjInspectorTab.ClientWidth-120
        ColWidths(2)=40'ObjInspectorTab.ClientWidth-120
        ColWidths(3)=40'ObjInspectorTab.ClientWidth-120
        ColWidths(4)=40'ObjInspectorTab.ClientWidth-120
        ColumnStyle(0)=gcsNone
        ColumnStyle(1)=gcsNone
        AddOptions=goThumbTracking, goDrawFocusSelected, goColSizing,  goEditing

        'Cell(0,0)="Name"
        'Cell(1,0)="Type"
        'Cell(2,0)="Parent"
        'RowHeights(0)=-1
        'RowHeights(1)=-1
        Cell(0,0)="PROPERTY"
        Cell(1,0)="VALUE"
        Cell(2,0)="ALIAS"
        ScrollBars=ssBoth'Vertical
        OnKeyPress=PropertyGridOnKeyPress
        OnSelectCell=EditPropertyField
        OnDrawCell=PropertyGridOnDrawCell 'HideEditCtls
      END CREATE


      CREATE DefaultPropertyGrid AS QSTRINGGRID                      ' Properties of selected component
        Align=alBottom'alClient
        height=200
        RowCount=10
        DefaultRowHeight=16
        FixedRows=0
        FixedCols=0
        ColCount=6
        Separator=chr$(09)
        color=&HFFECBD 'clw'
        ColWidths(0)=100
        ColWidths(1)=100'ObjInspectorTab.ClientWidth-120
        ColWidths(2)=100'ObjInspectorTab.ClientWidth-120
        ColumnStyle(0)=gcsNone
        ColumnStyle(1)=gcsNone
        AddOptions=goThumbTracking, goDrawFocusSelected, goColSizing,  goEditing
        visible=1
      END CREATE

      CREATE MethodGrid AS QSTRINGGRID                        ' Methods of selected component
        Align=alClient
        RowCount=100
        DefaultRowHeight=16
        FixedRows=1
        FixedCols=0
        ColCount=2
        ColWidths(0)=100
        ColWidths(1)=ObjInspectorTab.ClientWidth-120
        ColumnStyle(0)=gcsNone
        ColumnStyle(1)=gcsNone
        Cell(0,0)="METHOD"
        Cell(1,0)="ASSIGNMENT"
        ScrollBars=ssVertical
        OnSelectCell=EditMethodField
        OnDrawCell=HideEditCtls
      END CREATE
      CREATE EventGrid AS QSTRINGGRID                         ' Events of selected component
        Align=alClient
        RowCount=100
        DefaultRowHeight=16
        FixedRows=1
        FixedCols=1
        ColCount=2
        ColWidths(0)=100
        ColWidths(1)=ObjInspectorTab.ClientWidth-120
        ColumnStyle(0)=gcsNone
        ColumnStyle(1)=gcsNone
        Cell(0,0)="EVENT"
        Cell(1,0)="SUBROUTINE"
        ScrollBars=ssNone
        'Visible=False
        OnSelectCell=EditEventField
        OnDrawCell=HideEditCtls
      END CREATE


      CREATE FieldEdit AS QEDIT                               ' Editing a single field
        Left=108
        Width=PropertyGrid.ColWidths(1)-24
        Height=PropertyGrid.DefaultRowHeight
        'OnKeyDown=FieldUpdateEdit
        OnKeyUp=FieldUpdateEdit
        'Visible=False
      END CREATE
      CREATE FieldBox AS QCOMBOBOX                            ' Editing a multi-choice field
        Left=108
        Width=PropertyGrid.ColWidths(1)
        Height=PropertyGrid.DefaultRowHeight
        DropDownCount=8
        Style=csDropDownList
        OnChange=FieldUpdateCombo
        'Visible=False
      END CREATE
    END CREATE
  END CREATE

  CREATE Splitter3TAb AS QSPLITTER '-- Note position
    Align = alleft
    'align=albottom
    Cursor = crhSplit
    color=clb
    Height = 6

  END CREATE



  CREATE DesignPan AS QPANEL
    Width=Screen.Width*3\4+2'00
    'Height=MainForm.ClientHeight-ToolBox.Height-stat.Height
    'Left=0
    'Top=ToolBox.Height
    color=&HD2F5AB'clm
    align=alleft

    CREATE LogEdit AS QRICHEDIT
      Left = 1
      Top = 1
      TabOrder = 8
      AddStrings "logedit"
      HideScrollBars=0
      HideSelection=0
      ScrollBars=3 'ssBoth = 3
      Wordwrap=1
      align=alclient
    END CREATE
    CREATE Splitter2TAb AS QSPLITTER '-- Note position
      Align = alleft
      'align=albottom
      Cursor = crhSplit
      color=clr
      Height = 4

    END CREATE
    CREATE EditRCpath AS QEDIT
      Text = "Compiler path"
      Left = 480
      Top = 1
      width=150
      'OnKeyDown=cmpEditOnKeyDown
      'OnKeyUp=cmpEditOnKeyUp
      Align=alTop

    END CREATE
    CREATE Button1 AS QBUTTON
      Caption = "..."
      Left = 637
      width=20
      height=20
      Top = 3
      'OnClick=OnClick
      Align=alleft'Top
      visible=0

    END CREATE



    CREATE DesignTab AS QTABCONTROL
      Width=DesignPan.ClientWidth-500
      Height=DesignPan.ClientHeight
      Align=alleft'Top
      TabHeight=24
      TabWidth=100
      TabInactiveColor=&hbfbfbf
      Font.Color=&h7f7f00
      'color=clm
      AddTabs "Form Designer","RapidQ Coder","Menus","FreeBasic Coder","Help","RQObj Info"
      OnChange=DesignTabChange
      CREATE RichEdit1 AS QRICHEDIT
        Left = 1
        Top = 1
        TabOrder = 8
        AddStrings "RichEdit1"
        HideScrollBars=0
        HideSelection=0
        ScrollBars=3 'ssBoth = 3
        Wordwrap=1
        height=150
        align=albottom' alclient
      END CREATE

      CREATE RQObjPanel AS QPANEL                             ' Container for global grid
        Align=alClient
        BevelWidth=2
        BorderStyle=bvLowered
        Color=&HF0CD8E '&hdfdfdf
        CREATE RQObjPanel1 AS QPANEL                             ' Container
          Align=alClient
          BevelWidth=2
          BorderStyle=bvLowered
          Color=&HF0CD8E '&hdfdfdf
          create RQCompGlobalGrid as Qstringgrid
            Align=alClient
            RowCount=100
            DefaultRowHeight=16
            DefaultColWidth=100
            AddOptions(goEditing,goRowSizing,goColSizing)
            FixedRows=1
            FixedCols=1
            ColCount=9
            ColWidths(0)=100
            ColWidths(1)=500'ObjInspectorTab.ClientWidth-120
            ColWidths(2)=100'ObjInspectorTab.ClientWidth-120
            ColWidths(3)=30'ObjInspectorTab.ClientWidth-120
            ColWidths(4)=50
            ColWidths(5)=150
            ColWidths(6)=80
            ColWidths(7)=30
            ColWidths(8)=30
            ColumnStyle(0)=gcsNone
            ColumnStyle(1)=gcsNone
            Cell(0,0)="QObj"
            Cell(1,0)="Properties/Methods/Events"
            Cell(2,0)="Name"
            Cell(3,0)="R/W"
            Cell(4,0)="Default"
            Cell(5,0)="list"
            Cell(6,0)="Type"
            Cell(7,0)="Support"
            Cell(8,0)="#"
            'Visible=False

            onselectcell=GlobalGridselectcell
            ondrawcell=GlobalGridondrawcell
            Separator=chr$(9)

          end create

        END CREATE
        CREATE SplitterGlob AS QSPLITTER '-- Note position
          Align = alright'alleft
          'align=albottom
          Cursor = crhSplit
          color=clb
          width = 6

        END CREATE

        CREATE RQObjPanel2 AS QPANEL                             ' Container
          Align=alright
          BevelWidth=2
          BorderStyle=bvLowered
          Color=&HF0CD8E '&hdfdfdf
          width=50
        END CREATE
      END CREATE

      CREATE FormsPanel AS QPANEL                             ' Container for form designer
        Align=alClient
        BevelWidth=2
        BorderStyle=bvLowered
        Color=&HF0CD6E '&hdfdfdf
      END CREATE
      CREATE CodeText AS QRichEdit                            ' Code text screen RapidQ
        Align=alClient
        ScrollBars=ssBoth
        Color=&hffffef
        Font.Name="courier"
        Font.Size=10
        Font.Color=&hbf1f1f
        PlainText=True
        PopUpMenu=codeMenu
        Visible=False
      END CREATE

      CREATE SrcEdit AS QRICHEDIT
        Align = albottom 'client'Top
        ScrollBars = 3
        TabOrder = 10
        height=400
        'AddStrings "--- source --"
        Wordwrap=false
        color=&ha2cfce'cl
        HideSelection=false
        OnMouseDown=RichEditOnMouseDown
        OnKeyDown=SrcEditOnKeyDown
        OnKeyUp=SrcEditOnKeyUp
        WantTabs=1
        tag=33
        plaintext=1
        visible=1
        Font.Name="FixedSys"
        'Font=StrFont1
      END CREATE

      ' NB For Menu Designer TAB - see MenuPanel below
      CREATE FBCodeText AS QRichEdit                            ' Code text screen FreeBasic
        Align=alClient
        ScrollBars=ssBoth
        Color=&hffffef
        Font.Name="courier"
        Font.Size=10
        Font.Color=&hbf1f1f
        PlainText=True
        PopUpMenu=codeMenu
        Visible=False
      END CREATE
      CREATE HelpText AS QRichEdit                            ' Help screen
        Align=alClient
        ScrollBars=ssVertical
        Color=&hefffef
        Font.Name="courier"
        Font.Size=10
        Font.Color=&h004f00
        PlainText=True
        ReadOnly=True
        Visible=False
      END CREATE
    END CREATE
  END CREATE



END CREATE

CREATE MenuPanel AS QPANEL                                          ' Simple menu template screen
  Parent=DesignTab
  Align=alClient
  BevelWidth=2
  BorderStyle=bvLowered
  Color=&hdfffff
  Visible=1'False
  CREATE MenuText AS QRichEdit
    Width=MenuPanel.ClientWidth*2\3
    Height=MenuPanel.ClientHeight-150
    Left=(MenuPanel.Width-MenuText.Width)\2
    Top=MenuPanel.Top+100
    ScrollBars=ssVertical
    Color=&hcfefef
    Font.Name="courier"
    Font.Size=10
    Font.Color=&h1f3f3f
    PlainText=True
    ReadOnly=True
  END CREATE
  CREATE btnMMenu AS QBUTTON
    Width=145
    Left=MenuText.Left
    Top=20
    Caption="Add QMainMenu"
    Font.Color=&h009f00
    Font.Bold=3
    OnClick=AddMainMenu
  END CREATE
  CREATE cbMMenu AS QCOMBOBOX
    Left=MenuText.Left
    Top=50
    Font.Color=0
    OnChange=ParentChange
  END CREATE
  CREATE btnPMenu AS QBUTTON
    Width=145
    Left=MenuText.Left+MenuText.Width-145
    Top=20
    Caption="Add QPopupMenu"
    Font.Color=&h009f00
    Font.Bold=3
    OnClick=AddPopupMenu
  END CREATE
  CREATE btnUpdate AS QBUTTON
    Width=100
    Height=60
    Left=MenuText.Left+MenuText.Width\2 - 50
    Top=20
    Caption="Insert code"
    Font.Color=&hbf
    Font.Bold=3
    Tag=0
    OnClick=UpdateProjectMenu
  END CREATE
  CREATE chkMenu AS QCHECKBOX
    Width=180
    Left=MenuText.Left+MenuText.Width\2 - 90
    Top=110
    Caption="Add 'non-defaults' as comments"
    Font.Color=0
    Checked=False
    OnClick=OptionChange
  END CREATE
END CREATE

$INCLUDE "inc\RapidFRM_Mods.inc"                                        ' Courtesy of JohnK


pidx=0
RQ2incList.loadfromfile("inc\RapidQ2.inc")
'for i=0 to spflist.ItemCount-1 '

for i=0 to RQ2incList.ItemCount-1
  if trim$(lcase$(field$(RQ2incList.Item(i)," ",1)))="const" then

    PropertyList.AddItems(RQ2incList.Item(i))
    'call  AddClrString ("685:RQ2incList.Item("+str$(i)+")="+(RQ2incList.Item(i)), clred, LogEdit)
    'print"RQ2incList.Item(i)=";RQ2incList.Item(i)
    'CONST prSpace = 4
    inc pidx
  end if
next


'OldStringGridWndProc = SetWindowLongAPI(RQCompGlobalGrid.Handle, GWL_WNDPROC, CODEPTR(StringGridWndProc))

call  AddClrString ("199:StartPath$="+(StartPath$), clred, LogEdit)


'!!!--определение новой процедуры RichEdit'
OldRichEditWndProc = SetWindowLongAPI(SrcEdit.Handle, GWL_WNDPROC, CODEPTR(RichEditWndProc))


DZGini.Section="Compiler "
EditRCPath.text=DZGini.get("CompPath",StartDir)  ' curdir$+"\projects\")
call  AddClrString ("386 EditRCPath.text="+(EditRCPath.text), clb, LogEdit)

if direxists(EditRCPath.text)=0 then
  EditRCPath.text=StartDir
  DZGini.write("CompPath",StartDir )

end if


MainForm.ShowModal


'!*****************************************
SUB New_Click
END SUB

'!*****************************************
SUB Open_Click
  'OpDialog.Filter = "Basic Files (*.bas)|*.bas"
  OpDialog.Filter="Rapid-Q source files|*.bas;*.rq;*.rqb;*.inc|All files (*.*)|*.*"
  IF OpDialog.Execute Then
    SrcFileName$=OpDialog.Filename
    SrcEdit.text = loadString(SrcFileName$)
    'StatusPanel5.caption =SrcFileName$


  END IF
  HiLight (SrcEdit.handle,HiLiteFont.handle,strptr,HotTAbHL)'-<<<<<<<<<<<<<<<<<<<<<<<<'

  'call  AddClrString ("1388:Open_Click BuildObjTree="+str$(BuildObjTree), clo, LogEdit)


  BuildObjTree

  '!!! сюда вставляем компиляцию,запуск и сохранение свойств в таблицы компонентов на !!!__форме приложения__!!!.
  ' список окон сформирован, читаем его и формируем строку, добавляемую в исходник перед Form.ShowModal

  PropStr$=crlf+_
  "StartPath$ = COMMAND$(0)-Application.ExeName"+crlf+_
  " dim PropList as QStringList "+crlf ' строка добавляемая в исходник

  call  AddClrString ("1477:PropStr$="+(PropStr$), clred, LogEdit)
  'dim PropStr as QStringList

  for cbi=0 to cmboxObj.ItemCount-1
    ObjName$=field$(cmboxObj.Item(cbi)," ",1) '!!!  form1
    objtype$=trim$(field$(cmboxObj.Item(cbi)," as",2)) ' если не свойств Heith  и тп, то не обрабатывать
    objtype$=trim$(field$(objtype$," ",1)) ' если не свойств Heith  и тп, то не обрабатывать
    'call  AddClrString ("1498:objtype$="+(objtype$), clb, LogEdit)

    ' dim PropList as QStringList
    'PropList.addItem ("Form.height="+str$(Form.height)+crlf)
    if lcase$(objtype$)<>lcase$("QMainMenu") and lcase$(objtype$)<>lcase$("QMenuItem")  and lcase$(objtype$)<>lcase$("QPopupMenu")  then
      'call  AddClrString ("1488:ObjName$="+(ObjName$), clred, LogEdit)

      PropStr$=PropStr$+"PropList.addItems ("+qt+ObjName$+".height="+qt+"+str$("+ObjName$+".height))"+crlf
      PropStr$=PropStr$+"PropList.addItems ("+qt+ObjName$+".width="+qt+"+str$("+ObjName$+".width))"+crlf
      PropStr$=PropStr$+"PropList.addItems ("+qt+ObjName$+".top="+qt+"+str$("+ObjName$+".top))"+crlf
      PropStr$=PropStr$+"PropList.addItems ("+qt+ObjName$+".left="+qt+"+str$("+ObjName$+".left))"+crlf
    end if
    'PropStr.addItems (PropStr$)
  next cbi
  'call  AddClrString ("1805:cbi="+str$(cbi), clred, LogEdit)

  'call  AddClrString ("1808:StartPath$="+(StartPath$), cldb, LogEdit)

  kill StartPath$+"PropList.txt"


  PropStr$=PropStr$+"PropList.SaveToFile("+qt+StartPath$+"PropList.txt"+qt+")"+crlf

  '!!! вставляем сформированную строку в файл исходника перед Form.ShowModal
  ShModal=INSTR(1,lcase$(SrcEdit.text) , lcase$(".ShowModal")) '-- returns 7
  SrcEdit.SelStart=ShModal
  ShModal=SrcEdit.LINEINDEX
  SrcEdit.text=INSERT$(PropStr$,SrcEdit.text,ShModal)


  '!!! ---- compile and run -----------------

  SrcFileNameDsg$="SrcEditDsg.bas"
  SrcEdit.SaveToFile(SrcFileNameDsg$)

  'SrcFileNameQT$=qt+SrcFileName$+qt
  'EditRCpath.text
  cmpFileName$=qt+EditRCpath.text+"rc.exe"+qt '' : print "cmpFileName$=" ,cmpFileName$
  call AddClrString ( "1602: cmpFileName$= "+cmpFileName$, cldred, LogEdit)

  IncPathOpt$=C_Style (" -I"+qt+EditRCpath.text+"inc\" +qt)
  LibPathOpt$=C_Style (" -L"+qt+EditRCpath.text+"lib\" +qt)

  CompileStr$=cmpFileName$+" -r "+_
  IncPathOpt$+_
  LibPathOpt$+_
  " "+SrcFileNameDsg$

  call  AddClrString ("1534:CompileStr$="+(CompileStr$), cldg, LogEdit)

  PID=SHELL (CompileStr$,0)

  'call AddClrString (PrjPathEdit.text+"rc1.bat"+" "+cmpFileName$+" "+IncPathEdit.text+" "+LibPathEdit.text+" "+SrcFileNameQT$+" "+ExeFileName$+" "+msgFile$, clred, LogEdit)
  call AddClrString ( "PID= "+str$(PID), clblack, LogEdit)

  WaitForSingleObject (PID, &HFFFF)

  msgFile$="DUMP.$$$": ''  print "msgFile$=" ,msgFile$
  'call AddClrString ( "msgFile$= "+msgFile$, cldred, LogEdit)

  rezcmp$=LoadString(msgFile$-qt)
  'call  AddClrString ("msgFile$="+(rezcmp$), clm, LogEdit)


  ExeFileName$=FullPathNoExt(SrcFileNameDsg$)+".exe"
  'call  AddClrString ("1533:ExeFileName$="+(ExeFileName$), clred, LogEdit)

  PIDexe = SHELL(ExeFileName$, 1)
  'call  AddClrString ("1536:PIDexe="+str$(PIDexe), clred, LogEdit)
  '!!! ---- END compile and run -----------------


  'brem 0

  iiij=0

  waitforPropList:

  if fileexists(StartPath$+"PropList.txt")>0 then
    PropList.LoadFromFile (StartPath$+"PropList.txt")
  else
    WaitForSingleObject (PIDexe, 200)
    inc iiij
    call  AddClrString ("1604: File not found "+(StartPath$+"PropList.txt"), cldg, LogEdit)

    if  iiij<100 then goto waitforPropList

  end if
  'PropStr$=PropStr$+"PropList.SaveToFile("+qt+StartPath$+"PropList.txt"+qt+")"+crlf



  '!!!!BuildObjTree

  '!!  перебираем по списку компонентов из комбобокса, и
  '!! заменяем свойства значениями из PropList.txt.

  for cbi=0 to cmboxObj.ItemCount-1
    objname$=trim$(field$(cmboxObj.Item(cbi)," ",1))
    'call  AddClrString ("1607:objname$="+(objname$), cldg, LogEdit)

    GridFileName$=projectDir$+"\"+objname$+".dat"

    'call  AddClrString ("***************************** 2081:GridFileName$="+(GridFileName$), clp, LogEdit)
    PropertyGrid.RowCount=5
    PropertyGrid.LoadFromFile(GridFileName$,0,0,1000) ' загружаем таблицу свойств для компонента из списка

    objtype$=trim$(field$(cmboxObj.Item(cbi)," as ",2))
    objtype$=trim$(field$(objtype$," ",1))

    'call  AddClrString ("2091:objtype$=="+(objtype$), cldg, LogEdit)

    ' теперь ищем в PropList строки содержащие имя компонента objname$ и меняем в таблице свойств
    ' соответствующие свойства
    'sillyform.left=820
    'logpanel.height=548

    for i=0 to PropList.ItemCount-1
      PropName0$=(field$(PropList.Item(i),".",1))

      '!!!!!if instr(PropList.Item(i), objname$)>0  then
      if  PropName0$=objname$  then
        ' если в строке содержится имя объекта, то меняем свойство  в таблице

        PropName1$=(field$(PropList.Item(i),".",2))
        PropName$=(field$(PropName1$,"=",1))
        'call  AddClrString ("1638:PropName$="+(PropName$), &H00FF1F, LogEdit)
        PropValue$=(field$(PropName1$,"=",2))
        'call  AddClrString ("1640:PropValue$="+(PropValue$), clm, LogEdit)
        ' перебираем по таблице свойств и ищем соответствующее свойство

        for ri=1 to PropertyGrid.RowCount-1
          if lcase$(trim$(PropertyGrid.Cell(0,ri)))=lcase$(PropName$) then
            PropertyGrid.Cell(1,ri)=PropValue$
            'call  AddClrString ("1918:PropValue$="+(PropValue$), clb, LogEdit)
          end if
        next

      else

      end if

    next i

    GridFileName$=projectDir$+"\"+objname$+".dat"
    'call  AddClrString ("1658:OpenClick GridFileName$="+(GridFileName$), clred, LogEdit)
    PropertyGrid.SaveToFile(GridFileName$,0,0,PropertyGrid.RowCount)


    brem 0
    =================================================================
    DefGridFileName$=StartDir+"data\"+objtype$+".data"
    erem


  next  cbi






  call  AddClrString ("1391:Open_Click ShowObjects="+str$(ShowObjects), cl0, LogEdit)

  ShowObjects


END SUB

'*****************************************
SUB Save_Click
  IF SrcFileName$ = "Noname.bas" Then SaveAs_Click

END SUB

'*****************************************
SUB SaveAs_Click
  SvDialog.Filter = "Basic Files (*.bas)|*.bas"
  IF SvDialog.Execute Then
    'SourceFile2 = SvDialog.Filename
    SrcFileName$ = SvDialog.Filename
  END IF
END SUB

'*****************************************
SUB Compile_Click
END SUB

'*****************************************
SUB Run_Click
END SUB


'*****************************************
SUB CompOk_Click
END SUB

'*****************************************
SUB Print_Click
END SUB

'*****************************************
SUB Exit_Click
END SUB

'*****************************************
SUB Undo_Click
END SUB

'*****************************************
SUB Redo_Click
END SUB

'*****************************************
SUB Cut_Click
END SUB

'*****************************************
SUB Copy_Click
END SUB

'*****************************************
SUB Paste_Click
END SUB

'*****************************************
SUB SelectAll_Click
END SUB

'*****************************************
SUB Delete_Click
END SUB

'*****************************************
SUB Lower_Click
END SUB

'*****************************************
SUB Upper_Click
END SUB

'*****************************************
SUB Capital_Click
END SUB

'*****************************************
SUB Find_Click
END SUB

'*****************************************
SUB Replace_Click
END SUB

'*****************************************
SUB About_Click
END SUB


'*****************************************
FUNCTION  RichEditWndProc (hWnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
  ''call  AddClrString ("645:uMsg="+str$(uMsg), clred, LogEdit)

  'if NoPaint=2 then exit function
  'SubCount++

  ''call  AddClrString ("536:WM_MOUSEWHEEL="+str$(WM_MOUSEWHEEL), clred, LogEdit)


  if NoPaint=1 and  uMsg=WM_PAINT then exit function
  Result =  CallWindowProc(OldRichEditWndProc, hWnd, uMsg, wParam, lParam)

  SELECT CASE uMsg
  case WM_MOUSEWHEEL

    'goto noMOUSEWHEEL1

    if wParam> 0 then
      result= SendMessageAPI (hWnd,EM_LINESCROLL,0,-2)
    else
      result= SendMessageAPI (hWnd,EM_LINESCROLL,0,2)
    end if
    noMOUSEWHEEL1:

  CASE  WM_PAINT '---- <--------------------
    FIRSTVISIBLELINE= SendMessageAPI (hWnd,EM_GETFIRSTVISIBLELINE,0,0)
    ''call  AddClrString ("579:FIRSTVISIBLELINE="+str$(FIRSTVISIBLELINE), clred, LogEdit)
    'FirstChar=SendMessageAPI (hWnd,EM_LINEINDEX,line_number,0)

    if SrcEdit.LineCount<>SrcEditLineCount then
      SrcEditLineCount=SrcEdit.LineCount
      LineNumList.clear
      for i=0 to SrcEdit.LineCount+2' -1
        LineNumList.AddItems  str$(i+1)
      next i
      '!!MarginEdit.text= LineNumList.text
      '!!MarginEdit.visible=1
      lbzzz=1
    end if

    if  OldFirstVisLine <> FIRSTVISIBLELINE or lbzzz=1 then
      MarginChar=SendMessageAPI (MarginEdit.handle,EM_LINEINDEX,FIRSTVISIBLELINE,0)
      '!!MarginEdit.SelStart=len(MarginEdit.Text)-4
      '!!MarginEdit.SelStart=MarginChar
      OldFirstVisLine = FIRSTVISIBLELINE
      lbzzz=0
    else
    end if

    'if SyntaxHLBox.checked=0 then exit function
    'hWnd
    'HiLight (SrcEdit.handle,HiLiteFont.handle,@HLColor(0),strptr,HotTAbHL)'-<<<<<<<<<<<<<<<<<<<<<<<<'
    HiLight (SrcEdit.handle,HiLiteFont.handle,strptr,HotTAbHL)'-<<<<<<<<<<<<<<<<<<<<<<<<'
    'HiLight (hWnd,HiLiteFont.handle,strptr,HtHLBox.checked)'-<<<<<<<<<<<<<<<<<<<<<<<<'

  end select

END FUNCTION


'-- ************************************************************************'
sub SrcEditOnKeyDown (Key, Shift )
  ''call  AddClrString ("7104:Key="+str$(Key), clred, LogEdit)

  if  key=13 then

    if KeyDowned=0 then
      SrcEditWhereX=SrcEdit.WhereX
      OldClipBrd$=clipboard.text
      numtab0=tally(SrcEdit.Line(SrcEdit.WhereY-1),ht)
      numtab1=tally(SrcEdit.Line(SrcEdit.WhereY),ht)
      numtab2=tally(SrcEdit.Line(SrcEdit.WhereY+1),ht)
      txtleft$=left$(SrcEdit.Line(SrcEdit.WhereY),SrcEdit.WhereX)
      txtright$=right$(SrcEdit.Line(SrcEdit.WhereY),len(SrcEdit.Line(SrcEdit.WhereY))-SrcEdit.WhereX)
      numtabR=tally(txtright$,ht)
      'if numtabR=0 then ntab=numtab0 else ntab=numtabR
      clipboard.text=STRING$(numtabR, ht)
      SrcEdit.PasteFromClipboard
      lentxtr=len(txtright$-"ht")

      if lentxtr>0 then numtab=numtab1 else  numtab=numtab2
      clipboard.text=STRING$(numtab-numtabR, ht)
      KeyDowned=1
    else
      SrcEdit.PasteFromClipboard
    end if
  elseif key =VK_DELETE then
    ''call  AddClrString ("687:VK_DELETE="+str$(VK_DELETE), clred, LogEdit)
    'if SrcEdit.WhereX=0 and (SrcEdit.Line(SrcEdit.WhereY)-ht)="" then
    if (SrcEdit.Line(SrcEdit.WhereY)-ht)="" then
      SrcEdit.SelStart=SrcEdit.LINEINDEX
      SrcEdit.SelLength=len(SrcEdit.Line(SrcEdit.WhereY))
      SrcEdit.SelText=""

    end if
  else

  end if

end sub

'-- ************************************************************************'
sub SrcEditOnKeyUp (Key AS WORD, Shift AS INTEGER)

  if  key=13  then
    ''call  AddClrString ("7169:KeyDowned="+str$(KeyDowned), clb, LogEdit)
    if KeyDowned=1 then
      SrcEdit.PasteFromClipboard
      clipboard.text=OldClipBrd$
    elseif KeyDowned=2 then
      clipboard.text=OldClipBrd$
    end if
    ''call  AddClrString ("6474: UP ------- clipboard.text="+(clipboard.text), clDG, LogEdit)
  end if
  KeyDowned=0

  R2Change

end sub


'!-- ************************************************************************'
sub R2Change

  RichRow1=str$(SrcEdit.WhereY+1)
  RichCol1=str$(SrcEdit.WhereX+1)

  if SrcEdit.SelStart+1< len(SrcEdit.Text) then
    pos1=SrcEdit.SelStart+1
  else
    pos1=SrcEdit.SelStart
  end if

  char1$ = str$(asc(mid$(SrcEdit.Text, pos1,1)))
  'RichX1.Caption= RichRow1+":"+RichCol1 +"    "+char1$
  'RichX1.Font.Color=clBlue
  SrcEditLen1=len (SrcEdit.text)

  'SrcEdit.SelStart=CursWin(WindowsIndex)

  ''    AddPanels "Строка ", "Столбец ", "Код символа","Номер символа в тексте"
  StatusBar.Panel(0).caption = "Row "+RichRow1+":"+  str$(SrcEdit.LineCount)
  StatusBar.Panel(1).caption = "Col "+RichCol1
  StatusBar.Panel(3).caption = "Asc "+char1$
  StatusBar.Panel(2).caption = "Pos "+str$(pos1)+":"+  str$(SrcEditLen1)

  if SrcEditLen<>SrcEdit.LineCount then 'SrcEditLen1 только при изменении числа строк
    SrcEditLen=SrcEdit.LineCount
    Modiflg=1
  end if
END SUB
'-- ************************************************************************'
sub RichEditOnMouseDown
  R2Change
END SUB




'*****************************************
Sub BuildObjTree
  call  AddClrString ("1967:BuildObjTree="+str$(BuildObjTree), subclr, LogEdit)

  'DEFINT ObjectIndex    ' global index of added objects - added from component palette ans added from source parsing !!!
  'DIM ObjectType(0 TO MAX_OBJECTS) AS string                          '!!! Component's type ie  QPANEL, QButton etc
  'DIM ObjectHandle(0 TO MAX_OBJECTS) AS long                          '!!! Component's handle
  'DIM ObjectName(0 TO MAX_OBJECTS) AS string                          '!!! Component's name  ie Edit1, Panel1, StrinGrid3 etc

  'dim ObjParentIdx(0 TO MAX_OBJECTS) AS integer  ' ObjectIndex of the parents of the component(ObjectIndex) !!!
  ' well.. if component(ObjectIndex) has a parent - ObjectIndex of this parent stored in ObjParentIdx(ObjectIndex), so
  'handle of the parent of component(ObjectIndex) stored in ObjectHandle(ObjParentIdx(ObjectIndex))

  dim OperList as QStringList

  'OperList.Text=SrcEdit.Text

  OperList.clear

  GetOpersList (SrcEdit,OperList) '!!! заполняем масcив начальных и конечных позиций операторов для подсветки при перемещении по шагам.

  OperList.SaveToFile(StartDir+"Opers.lst")

  'GetOperators1 (Oper$() as string,OperPos() as integer, OperLen() as integer, SrcTxt$ as string,NumOpers as long)
  'call GetOperators1 (~Op() ,~OpPos(),~OpLen(), OperList.Text, @opercnt)

  LevelCount=256
  LevelIdx=-1
  PropCount=0

  dim ObjIdx(256)
  dim Parent$(256)


  cmboxObj.Clear
  ObjectIndex=-1
  ObjectCount=0
  ObjParentIdx(0)=-1
  oldObjIdx=-1


  for i=0 to MAX_OBJECTS ' очищаем данные компонентов
    ObjectType(i)=""     '!!! Component's type ie  QPANEL, QButton etc
    ObjectHandle(i)=-1   '!!! Component's handle
    ObjectName(i)=""     '!!! Component's name  ie Edit1, Panel1, StrinGrid3 etc
    ObjParentIdx(i)=-1   ' ObjectIndex of the parents of the component(ObjectIndex) !!!
  next i


  ' если отсутствует, то создаем директорию проекта
  projectDir$=ExtractFileName(SrcFileName$)
  projectDir$=FileNameNoExt(projectDir$)
  projectDir$=StartDir+projectpath$+projectDir$
  call  AddClrString ("962:projectDir$="+(projectDir$), clb, LogEdit)
  if direxists(projectDir$)=0 then
    mkdir projectDir$
  end if


  'Gauge1.Forecolor=clM:Gauge1.visible=1: Gauge1.position=30
  brem 0
  '!!!!====================================================
  1. Ищем CREATE или END CREATE
if CREATE then
  если level>0 то сохраняем GridFileName$
  2. inc level
  objname$=trim$(field$(LSrc$," as",1))= >GridFileName$
  objtype$= >DefGridFileName$

elseif END CREATE то
если level>0 то сохраняем GridFileName$
2. dec level
objname$= >GridFileName$
objtype$= >DefGridFileName$

загружаем PropertyGrid GridFileName$ если раньше сохраняли
goto п 1
else
3. дополняем свойствами PropertyGrid
goto п 1
end if
'!!!!====================================================
erem

for ri=1 to PropertyGrid.RowCount-1  '! очищаем  PropertyGrid
  for cj=0 to PropertyGrid.ColCount-1
    PropertyGrid.Cell(cj,ri)=""
  next
next

PropertyGrid.RowCount=2


for i=0 to OperList.ItemCount-1
  LFAke$=LCase$(OperList.Item(i))-ht
  LSrc$=trim$(LFAke$)
  call DelComments(@LSrc$)
  LSrc$=trim$(LSrc$)
  'call  AddClrString ("2304:LSrc$="+(LSrc$), clred, LogEdit)
  zzcreate=0
  zzEndcreate=0

  if instr(LSrc$, "create")>0   then '!Ищем CREATE или END CREATE

    zzcreate=GetVarPos(LSrc$, "create")
    'call  AddClrString ("2333:zzcreate="+str$(zzcreate), clred, LogEdit)
    zzEndcreate=GetVarPos(LSrc$-" ", "endcreate")
    'call  AddClrString ("2335:zzEndcreate="+str$(zzEndcreate), clred, LogEdit)

    if zzcreate=1 then '! if CREATE then будет новый уровень вложенности
      'call  AddClrString ("2338:zzcreate="+str$(zzcreate), clred, LogEdit)

      if LevelIdx>-1 then '! если level>0 то сохраняем GridFileName$
        if GridFileNameParse$>"" then
          'call  AddClrString ("2313:BuildObjTree save GridFileNameParse$="+(GridFileNameParse$), &H0000A9, LogEdit)
          PropertyGrid.SaveToFile(GridFileNameParse$,0,0,PropertyGrid.RowCount)


          for ri=1 to PropertyGrid.RowCount-1  '! очищаем  PropertyGrid
            for cj=0 to PropertyGrid.ColCount-1
              PropertyGrid.Cell(cj,ri)=""
            next
          next

          PropertyGrid.RowCount=2


        end if

      end if

      PropCount=0
      '! LevelIdx=0 ObjectCount=1 ObjectIndex=ObjectCount-1=0  parentIdx(ObjectIndex=0)=-1 parentIdx(ObjectIndex=4)=oldObjIdx=3
      oldObjIdx=ObjectIndex
      inc ObjectCount
      ObjectIndex=ObjectCount-1
      inc LevelIdx
      ObjParentIdx(ObjectIndex)=oldObjIdx
      'call  AddClrString ("2356:ObjParentIdx("+str$(ObjectIndex)+")="+str$(ObjParentIdx(ObjectIndex)), clred, LogEdit)

      'call  AddClrString ("2321:ObjectIndex="+str$(ObjectIndex), clred, LogEdit)
      'call  AddClrString ("2320:LevelIdx="+str$(LevelIdx), clred, LogEdit)

      LSrc$=lcase$(trim$(LSrc$-"create"))
      objname$=trim$(field$(LSrc$," as",1))
      'call  AddClrString ("2322:objname$="+(objname$), &H6600A9, LogEdit)
      objtype$=trim$(field$(LSrc$," as",2))
      'call  AddClrString ("2324:objtype$="+(objtype$), &H6600A9, LogEdit)

      cmboxObj.AddItems (LSrc$)
      cmboxObj.Text= (LSrc$)


      ObjectName(ObjectIndex)=objname$
      'call  AddClrString ("2327:ObjectName("+str$(ObjectIndex)+")="+(ObjectName(ObjectIndex)), &H664700, LogEdit)
      ObjectType(ObjectIndex)=objtype$
      'call  AddClrString ("2329:ObjectType("+str$(ObjectIndex)+")="+(ObjectType(ObjectIndex)), &H664700, LogEdit)

      GridFileNameParse$=projectDir$+"\"+objname$+".datP"
      'call  AddClrString ("2331:new GridFileNameParse$="+(GridFileNameParse$), &HE500AE, LogEdit)

      DefGridFileName$=StartDir+"data\"+objtype$+".data"
      'call  AddClrString ("2333:new DefGridFileName$="+(DefGridFileName$), &HE500AE, LogEdit)



    elseif zzEndcreate=1 then
      'call  AddClrString ("2394:zzEndcreate="+str$(zzEndcreate), clred, LogEdit)

      if LevelIdx>-1 then '! если level>-1 то сохраняем GridFileName$
        if GridFileNameParse$>"" then
          'call  AddClrString ("2313:BuildObjTree save GridFileNameParse$="+(GridFileNameParse$), &H0000A9, LogEdit)
          PropertyGrid.SaveToFile(GridFileNameParse$,0,0,PropertyGrid.RowCount)

        end if

        '!dec LevelIdx=1  ObjectIndex=parentIdx(ObjectIndex=2)= 1 ObjectCount=3 parentIdx(ObjectIndex=1)=0

        'call  AddClrString ("2360:before dec LevelIdx="+str$(LevelIdx), &H005F00, LogEdit)
        dec LevelIdx
        'call  AddClrString ("2360:LevelIdx="+str$(LevelIdx), &H005F00, LogEdit)

        'call  AddClrString ("2333: child ObjectName("+str$(ObjectIndex)+")="+(ObjectName(ObjectIndex)), &HaF4200, LogEdit)
        'call  AddClrString ("2334: child ObjectType("+str$(ObjectIndex)+")="+(ObjectType(ObjectIndex)), &HaF4200, LogEdit)

        'call  AddClrString ("2361:before dec  ObjectIndex="+str$(ObjectIndex), &HC25F00, LogEdit)
        'call  AddClrString ("2414:ObjparentIdx("+str$(ObjectIndex)+")="+str$(ObjparentIdx(ObjectIndex)), clred, LogEdit)
        ObjectIndex=ObjparentIdx(ObjectIndex)
        'call  AddClrString ("2415:ObjparentIdx("+str$(ObjectIndex)+")="+str$(ObjparentIdx(ObjectIndex)), clred, LogEdit)
        'call  AddClrString ("2361:ObjectIndex="+str$(ObjectIndex), &HC25F00, LogEdit)

        objname$=ObjectName(ObjectIndex)
        'call  AddClrString ("2353:ObjectName("+str$(ObjectIndex)+")="+(ObjectName(ObjectIndex)), &HFF4200, LogEdit)
        objtype$=ObjectType(ObjectIndex)
        'call  AddClrString ("2354:ObjectType("+str$(ObjectIndex)+")="+(ObjectType(ObjectIndex)), &HFF4200, LogEdit)

        GridFileNameParse$=projectDir$+"\"+objname$+".datP"
        'call  AddClrString ("2360:new GridFileNameParse$="+(GridFileNameParse$), &HE5000E, LogEdit)

        DefGridFileName$=StartDir+"data\"+objtype$+".data"
        'call  AddClrString ("2362:new DefGridFileName$="+(DefGridFileName$), &HE5000E, LogEdit)

        for ri=1 to PropertyGrid.RowCount-1  '! очищаем  PropertyGrid
          for cj=0 to PropertyGrid.ColCount-1
            PropertyGrid.Cell(cj,ri)=""
          next
        next

        PropertyGrid.RowCount=2


        PropertyGrid.LoadFromFile(GridFileNameParse$,0,0,1000) ' загружаем таблицу свойств для компонента из списка


      end if


    else

    end if

  elseif LevelIdx>-1 then '! 3. дополняем свойствами PropertyGrid
    'all  AddClrString ("2387:------------------------- LSrc$="+(LSrc$), clred, LogEdit)

    if PropertyGrid.Cell(0,PropertyGrid.RowCount-1)<>"" then
      PropertyGrid.RowCount=PropertyGrid.RowCount+1
    end if


    if instr(LSrc$,"=")=0 then
      method$=LSrc$
      PropertyGrid.Cell(0,PropertyGrid.RowCount-1)=method$ '    LSrc$ ' метод - center например
      '!!! PropCount остается от предыдущего!!!

    else ' присутствует знак равенства
      if instr(LSrc$,"qt")>0 then ' если строковая
        'call  AddClrString ("2393:LSrc$="+(LSrc$), clred, LogEdit)
        propName$= field$(LSrc$,"=",0)
        'call  AddClrString ("2395:propName$="+(propName$), clred, LogEdit)
        propValue$=field$(LSrc$,"=",1)-qt
        'call  AddClrString ("2397:propValue$="+(propValue$), clred, LogEdit)
        '!!!!! PropertyFieldUpdate(propName$, propValue$)
        PropertyGrid.Cell(0,PropertyGrid.RowCount-1)=propName$
        PropertyGrid.Cell(1,PropertyGrid.RowCount-1)=propValue$

      else ' если не строковая
        PropertyGrid.Cell(0,PropertyGrid.RowCount-1)=field$(LSrc$,"=",1) ' имя свойства
        vall$=trim$(field$(LSrc$,"=",2)) ' значение свойства
        'call  AddClrString ("2405:vall$="+(vall$), clred, LogEdit)
        if vall$="0" then ' нулевое значениеbn
          PropertyGrid.Cell(1,PropertyGrid.RowCount-1)=vall$
        else
          if val(vall$)=0 and vall$<>"0" then ' pyfxfybt 'то выражение или функция или именованная константа
            ' тут надо проверить на константы
            PropertyGrid.Cell(1,PropertyGrid.RowCount-1)=vall$
          end if
          PropertyGrid.Cell(1,PropertyGrid.RowCount-1)=vall$

        end if
      end if
      inc PropCount
      'call  AddClrString ("2418:PropCount="+str$(PropCount), clred, LogEdit)
      'if PropCount>PropertyGrid.RowCount-4 then
      'PropertyGrid.RowCount=PropertyGrid.RowCount+1
      'end if

    end if


  end if


next


brem 0
===================================================================
'!!Gauge1.visible=0:Gauge1.Forecolor=clR:
======================================
erem

ObjectCount=0

'exit sub '!!!! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

'!  перебираем по списку компонентов из комбобокса, и заполняем таблицу runtime значениями.

for cbi=0 to cmboxObj.ItemCount-1

  objname$=trim$(field$(cmboxObj.Item(cbi)," ",1))

  objtype$=trim$(field$(cmboxObj.Item(cbi)," as ",2))
  objtype$=trim$(field$(objtype$," ",1))

  'call  AddClrString ("2492:objtype$="+(objtype$), clred, LogEdit)
  'call  AddClrString ("2072:objname$="+(objname$), clred, LogEdit)

  for ri=1 to PropertyGrid.RowCount-1
    for cj=0 to PropertyGrid.ColCount-1
      PropertyGrid.Cell(cj,ri)=""
    next
  next

  PropertyGrid.RowCount=5

  GridFileNameParse$=projectDir$+"\"+objname$+".datP"
  'call  AddClrString ("2499:new GridFileNameParse$="+(GridFileNameParse$), &HE5000E, LogEdit)

  DefGridFileName$=StartDir+"data\"+objtype$+".data"
  'call  AddClrString ("2502:new DefGridFileName$="+(DefGridFileName$), &HE5000E, LogEdit)


  GridFileName$=projectDir$+"\"+objname$+".dat"
  'call  AddClrString ("2081:GridFileName$="+(GridFileName$), clred, LogEdit)

  for ri=0 to DefaultPropertyGrid.RowCount-1
    for cj=0 to DefaultPropertyGrid.ColCount-1
      DefaultPropertyGrid.Cell(cj,ri)=""
    next
  next

  if fileexists (DefGridFileName$)>0 then
  else
    objtype$="qpanel" '"trim$(field$(objtype$," ",1))
    'call  AddClrString ("2101:objtype$="+(objtype$), clb, LogEdit)
    DefGridFileName$=StartDir+"data\"+objtype$+".data"
    DefaultPropertyGrid.LoadFromFile(DefGridFileName$,0,0,1000)

  end if


  if fileexists (DefGridFileName$)>0 then

    'call  AddClrString ("2092:DefGridFileName$="+(DefGridFileName$), cldg, LogEdit)
    DefaultPropertyGrid.LoadFromFile(DefGridFileName$,0,0,1000)

    PropertyGrid.RowCount=DefaultPropertyGrid.RowCount+1

    '! копируем данные из DefaultPropertyGrid в PropertyGrid
    '! в 0 столбец копируем данные из 0 столбца DefaultPropertyGrid
    '! в 1 столбец копируем данные из 2 столбца DefaultPropertyGrid
    '!!! убрать копирование функций обработчиков в таблицу Enents

    for r2=0 to EventGrid.RowCount-1
      for c2=0 to EventGrid.ColCount-1
        EventGrid.Cell(c2,r2)=""
      next
    next

    evRow=1
    'for i=1 to PropertyGrid.RowCount-1
    for ri=1 to PropertyGrid.RowCount-1
      'PropertyGrid.Cell(0,ri+1)=DefaultPropertyGrid.Cell(0,ri)
      'PropertyGrid.Cell(1,ri+1)=DefaultPropertyGrid.Cell(2,ri)

      'if lcase$(left$(DefaultPropertyGrid.cell(0,ri-1),2))="on" then
      'EventGrid.cell(0,evRow)=DefaultPropertyGrid.cell(0,ri-1)
      'inc evRow
      'if EventGrid.RowCount<evRow then EventGrid.RowCount=evRow

      'call  AddClrString ("2576:evRow="+str$(evRow), clred, LogEdit)
      'else
      PropertyGrid.cell(0,ri)=DefaultPropertyGrid.cell(0,ri-1) ' невидимая таблица для DefaultProperty
      PropertyGrid.cell(1,ri)=DefaultPropertyGrid.cell(2,ri-1)
      PropertyGrid.cell (3,ri)=str$(ri)
      PropertyGrid.cell (4,ri)=DefaultPropertyGrid.cell (1,ri-1)

      'end if
    next

    for ri=PropertyGrid.RowCount-1  to 1 step -1
      if PropertyGrid.cell (0,ri)="" then
        PropertyGrid.DeleteRow(ri)
      else
        exit for
      end if
    next ri



    '! поверх копируем данные из GridFileNameParse$ используя промежуточную таблицу PropertyListGrid
    for ri=0 to PropertyListGrid.RowCount-1
      for cj=0 to PropertyListGrid.ColCount-1
        PropertyListGrid.Cell(cj,ri)=""
      next
    next

    PropertyListGrid.LoadFromFile(GridFileNameParse$,0,0,1000)

    for ri=1 to PropertyGrid.RowCount-1
      for l2i=1 to PropertyListGrid.RowCount-1
        p1$=trim$(lcase$(    PropertyGrid.Cell(0,ri)))
        p2$=trim$(lcase$(PropertyListGrid.Cell(0,l2i)))

        'if lcase$(PropertyGrid.Cell(0,ri))=lcase$(PropertyListGrid.Cell(0,l2i)) then
        if p1$=p2$ then
          PropertyGrid.Cell(1,ri)=PropertyListGrid.Cell(1,l2i)
          exit for
        end if
      next l2i

    next ri

    PropertyGrid.SaveToFile(GridFileName$,0,0,PropertyGrid.RowCount)
    'call  AddClrString ("2239:GridFileName$="+(GridFileName$), clred, LogEdit)
  else


    for ri=1 to DefaultPropertyGrid.RowCount-1
      'call  AddClrString ("3573:ri="+str$(ri), clred, LogEdit)
      for cj=0 to DefaultPropertyGrid.ColCount-1
        DefaultPropertyGrid.Cell(cj,ri)=""
      next
    next

    DefGridFileName$=StartDir+"data\"+objtype$+".data"
    objtype$="qpanel" '"trim$(field$(objtype$," ",1))
    'call  AddClrString ("2149:objtype$="+(objtype$), clb, LogEdit)
    DefGridFileName$=StartDir+"data\"+objtype$+".data"
    DefaultPropertyGrid.LoadFromFile(DefGridFileName$,0,0,1000)

  end if





next  cbi

call  AddClrString ("==================== 2524:BuildOblectTree cbi="+str$(cbi), cldr, LogEdit)

End Sub







' create form as qform~0
' create mainmenu as qmainmenu | create form as qform ~ 1
' create mnufile as qmenuitem | create mainmenu as qmainmenu ~ 2
' create mnunew as qmenuitem | create mnufile as qmenuitem ~ 3

brem 0
'*****************************************
erem

'!*****************************************
Sub cmboxObjOnChange
  call  AddClrString ("1893:cmboxObjOnChange="+cmboxObj.Item(cmboxObj.ItemIndex), subclr, LogEdit)
  'call  AddClrString ("1991:cmboxObj.ItemIndex="+str$(cmboxObj.ItemIndex), clb, LogEdit)
  'call  AddClrString ("2030:cmboxObj.Item("+str$(cmboxObj.ItemIndex)+")="+(cmboxObj.Item(cmboxObj.ItemIndex)), clb, LogEdit)


  objname$=trim$(field$(cmboxObj.Item(cmboxObj.ItemIndex)," ",1))

  call  AddClrString ("2033:------ objname$="+(objname$), clred, LogEdit)

  'toolbox as qpanel  parent=mainform as qform
  GridFileName$=projectDir$+"\"+trim$(field$(cmboxObj.Item(cmboxObj.ItemIndex)," ",1)+".dat")
  call  AddClrString ("1969:GridFileName$="+(GridFileName$), clred, LogEdit)

  objtype$=trim$(field$(cmboxObj.Item(cmboxObj.ItemIndex)," as ",2))
  call  AddClrString ("2288:objtype$=="+(objtype$), clred, LogEdit)
  objtype$=trim$(field$(objtype$," ",1))
  call  AddClrString ("2290:objtype$="+(objtype$), clred, LogEdit)

  DefGridFileName$=StartDir+"data\"+objtype$+".data"
  'call  AddClrString ("2035:DefGridFileName$="+(DefGridFileName$), &H00BE77, LogEdit)


  if fileexists (DefGridFileName$)>0 then

  else

    objtype$="qpanel" '"trim$(field$(objtype$," ",1))
    'call  AddClrString ("2201:objtype$="+(objtype$), clp, LogEdit)
    DefGridFileName$=StartDir+"data\"+objtype$+".data"

  end if



  if fileexists (DefGridFileName$)>0 then

    for ri=0 to DefaultPropertyGrid.RowCount-1
      for cj=0 to DefaultPropertyGrid.ColCount-1
        DefaultPropertyGrid.Cell(cj,ri)=""
      next
    next
    DefaultPropertyGrid.LoadFromFile(DefGridFileName$,0,0,1000)
    call  AddClrString ("2603:DefGridFileName$="+(DefGridFileName$), clred, LogEdit)
    'PropertyGrid.LoadFromFile(DefGridFileName$,0,0,1000)

    'call  AddClrString ("1971:======= DefaultPropertyGrid.RowCount="+str$(DefaultPropertyGrid.RowCount), cldp, LogEdit)
  else ' !!! неизвестный компонент <<<<<<<<<<<<<
    Showmessage ("2220: File not found "+DefGridFileName$+" "+cmboxObj.Item(cmboxObj.ItemIndex))
    'call  AddClrString ("==================== 1990::DefGridFileName File not found "+DefGridFileName$, clY, LogEdit)
    objtype$="qpanel" '"trim$(field$(objtype$," ",1))
    'call  AddClrString ("2223:objtype$="+(objtype$), clp, LogEdit)
    DefGridFileName$=StartDir+"data\"+objtype$+".data"

  end if


  if fileexists (GridFileName$)>0 then
    PropertyGrid.RowCount=50
    for ri=1 to PropertyGrid.RowCount-1
      for cj=0 to PropertyGrid.ColCount-1
        PropertyGrid.Cell(cj,ri)=""
      next
    next

    PropertyGrid.RowCount=5


    ''call  AddClrString ("1984:PropertyGrid.RowCount="+str$(PropertyGrid.RowCount), cldg, LogEdit)
    PropertyGrid.LoadFromFile(GridFileName$,0,0,1000)
    '!!!PropertyGrid.LoadFromFile(DefGridFileName$,0,0,1000)
    'call  AddClrString ("2340: load GridFileName$="+(GridFileName$), clred, LogEdit)
    ''call  AddClrString ("1984:PropertyGrid.RowCount="+str$(PropertyGrid.RowCount), cldg, LogEdit)

    ObjNameGrid.Cell(0,1)=objname$'PropertyGrid.Cell(0,1)
    ObjNameGrid.Cell(1,1)=objType$'PropertyGrid.Cell(1,1)
    'ObjNameGrid.Cell(2,1)=PropertyGrid.Cell(2,1)

    statusBar.Panel(5).caption =GridFileName$
    '!!StatusPanel5.caption =GridFileName$
    'call  AddClrString ("2006:cmboxObjOnChange PropertyValueUpdate====!!! ", cldb, LogEdit)
    PropertyValueUpdate

  else
    Showmessage ("2015:File not found "+GridFileName$)
  end if



  for r2=0 to EventGrid.RowCount-1
    for c2=0 to EventGrid.ColCount-1
      EventGrid.Cell(c2,r2)=""
    next
  next

  evRow=1
  'for i=1 to PropertyGrid.RowCount-1
  for ri=1 to PropertyGrid.RowCount-1
    'PropertyGrid.Cell(0,ri+1)=DefaultPropertyGrid.Cell(0,ri)
    'PropertyGrid.Cell(1,ri+1)=DefaultPropertyGrid.Cell(2,ri)

    if lcase$(left$(DefaultPropertyGrid.cell(0,ri-1),2))="on" then
      EventGrid.cell(0,evRow)=DefaultPropertyGrid.cell(0,ri-1)
      inc evRow
      if EventGrid.RowCount<evRow then EventGrid.RowCount=evRow

      'call  AddClrString ("2576:evRow="+str$(evRow), clred, LogEdit)
    else

    end if
  next

  for ri=EventGrid.RowCount-1  to 1 step -1
    if EventGrid.cell (0,ri)="" then
      EventGrid.DeleteRow(ri)
    else
      exit for
    end if
  next ri




End Sub




'*****************************************
'--------------------------------Common functions-----------------------------------------
'FUNCTION TRIM$(inpString AS string) AS string
'Result=LTRIM$(RTRIM$(inpString))
'END FUNCTION

'*****************************************
' Which index of AddedObjectList() belongs to this component handle
FUNCTION HandleToIndex_OLD(hWnd AS long) AS integer
  DEFINT i
  DEFSTR tstr

  Result = -1
  FOR i=0 TO MAX_OBJECTS
    IF AddedObjectList(i)="" THEN EXIT FOR
    'call  AddClrString ("666:AddedObjectList("+str$(i)+")="+(AddedObjectList(i)), clp, LogEdit)
    tstr=FIELD$(AddedObjectList(i),"~",1)
    IF VAL(FIELD$(tstr,"|",3))=hWnd THEN
      Result=i
      EXIT FUNCTION
    END IF
  NEXT i
END FUNCTION

'*****************************************!
FUNCTION HandleToIndex(hWnd AS long) AS integer
  ''call  AddClrString ("2668:HandleToIndex=", subclr, LogEdit)
  DEFINT i
  DEFSTR tstr

  Result = -1
  FOR i=0 TO MAX_OBJECTS
    'IF AddedObjectList(i)="" THEN EXIT FOR
    ''call  AddClrString ("666:AddedObjectList("+str$(i)+")="+(AddedObjectList(i)), clp, LogEdit)
    'tstr=FIELD$(AddedObjectList(i),"~",1)
    'IF VAL(FIELD$(tstr,"|",3))=hWnd THEN
    IF ObjectHandle(i)=hWnd  THEN
      Result=i
      EXIT FUNCTION
    END IF
  NEXT i
END FUNCTION

'!*****************************************
' Update StatusBar with CurrentObject Info & CurrentForm
SUB UpdateStatus '!!!! <<<<<<<<<<<<<<< необновленные процедуры
  DEFSTR tstr, tok, strCaption
  'DEFINT ObjType
  DEFLNG hWnd

  tstr=FIELD$(AddedObjectList(ObjectIndex),"~",1)
  strCaption="Selection("+STR$(ObjectIndex)+") :: Type="+FIELD$(tstr,"|",2)+ _
  " :: Name="+FIELD$(tstr,"|",5)+" :: Handle="

  ''call  AddClrString ("695:strCaption="+(strCaption), clred, LogEdit)

  ObjType=VAL(FIELD$(tstr,"|",1))
  ''call  AddClrString ("913:ObjType="+str$(ObjType), clred, LogEdit)
  SELECT CASE ObjType
  CASE Q_COOLBTN,Q_OVALBTN,Q_TABCONTROL,Q_DIRTREE,Q_FILELISTBOX,Q_GAUGE, _
 Q_CANVAS,Q_IMAGE,Q_SPLITTER,NON_VISIBLE TO MAX_TOOLBTNS     ' Objects without "valid" handle
    strCaption=strCaption+"Undefined"
  CASE ELSE
    strCaption=strCaption+FIELD$(tstr,"|",3)
    IF objType>0 THEN
      hWnd=VAL(FIELD$(tstr,"|",3))
      hWnd=GetParent(hWnd)
      strCaption=strCaption+" :: Parent="+STR$(hWnd)
    END IF
  END SELECT
  stat.Panel(0).Caption=strCaption
  stat.Panel(1).Caption="  Active Form = "+STR$(FormIndex)
END SUB

'*****************************************
' Deselect everything - Current Form active
SUB Deselect '!!!! <<<<<<<<<<<<<<< необновленные процедуры
  DEFLNG hWnd
  DEFINT i
  DEFSTR tstr

  HideCarets                                                      ' If visible
  'FieldEdit.Visible=False
  'FieldBox.Visible=False
  DesignTab.TabIndex=0
  DesignTabChange
  IF designMenu.Tag>0 THEN                                        ' Copying something?
    designMenu.Tag=0                                            ' Cancel it
    FOR i=0 TO MAX_FORMS
      Forms(i).Cursor=crDefault                               ' Cursor back to default
    NEXT i
  END IF
  hWnd=Forms(FormIndex).Handle                                  ' Default to current form
  FOR i=0 TO ObjectIndex-1
    tstr=FIELD$(AddedObjectList(i),"~",1)
    IF VAL(FIELD$(tstr,"|",3))=hWnd THEN
      IF CurrentObject<>i THEN                                ' Not current form?
        CurrentObject=i                                     ' Set to current form
        UpdatePropGrid(i)                                   ' Update prop grid
        UpdateStatus
      END IF
      EXIT FOR
    END IF
  NEXT i
  NewObjectID=-1
END SUB

'*****************************************
' Returns true for objects that can have child objects (excluding forms)
FUNCTION IsTypeParent(ThisIdx AS integer) AS integer '!!!! <<<<<<<<<<<<<<<  необновленные процедуры
  call  AddClrString ("2731: +++ IsTypeParent ThisIdx="+str$(ThisIdx), cldm, LogEdit)

  DEFSTR tstr

  tstr=ObjectType(ThisIdx) 'FIELD$(AddedObjectList(ThisIdx),"~",1)                          ' First line of this object string
  'call  AddClrString ("2735:tstr="+ucase$(tstr), 3456, LogEdit)

  SELECT CASE  ucase$(tstr) 'FIELD$(tstr,"|",2)
  CASE "QPANEL","QTABCONTROL","QGROUPBOX","QSCROLLBOX"        ' NB do NOT include QFORMs
    Result=True
  CASE ELSE
    Result=False
  END SELECT
END FUNCTION

'*****************************************
' Get all direct siblings of this "start" object (non-parent types first)
FUNCTION FillSiblingList(StartIndex AS integer) AS string '!!!! <<<<<<<<<<<<<<<  необновленные процедуры
  call  AddClrString ("2747:FillSiblingList StartIndex="+str$(StartIndex), clo, LogEdit)
  '!!StartIndex - index объекта для которого ищутся его дети
  DEFINT i
  DEFSTR tstr, strParent, sibResult

  '!dim ObjParentIdx(0 TO MAX_OBJECTS) AS integer
  '! ObjectIndex of the parent of the component(ObjectIndex)
  'well.. if component(ObjectIndex) has a parent -
  'ObjectIndex of this parent stored in ObjParentIdx(ObjectIndex),so
  'handle of the parent of component(ObjectIndex) stored in
  'ObjectHandle(ObjParentIdx(ObjectIndex))


  sibResult=""
  'tstr=FIELD$(AddedObjectList(StartIndex),"~",1)

  strParent=FIELD$(tstr,"|",3)  ' Get handle of the start object
  'call  AddClrString ("2766:ObjectCount="+str$(ObjectCount), clg, LogEdit)

  FOR i=StartIndex+1 TO ObjectCount-1
    'call  AddClrString ("2767:ObjParentIdx("+str$(i)+")="+str$(ObjParentIdx(i)), clm, LogEdit)

    if ObjParentIdx(i)=StartIndex then

      sibResult=sibResult+STR$(i)+"|"                     ' Add its index to the list
      'call  AddClrString ("2772:sibResult="+(sibResult), clb, LogEdit)

    end if
  NEXT i

  goto siblEnd

  FOR i=StartIndex+1 TO ObjectIndex-1
    IF IsTypeParent(i)=False THEN
      tstr=FIELD$(AddedObjectList(i),"~",1)
      IF strParent=FIELD$(tstr,"|",6) THEN                    ' Is this a sibling?
        sibResult=sibResult+STR$(i)+"|"                     ' Add its index to the list
      END IF
    END IF
  NEXT i

  FOR i=StartIndex+1 TO ObjectIndex-1
    IF IsTypeParent(i)=True THEN
      tstr=FIELD$(AddedObjectList(i),"~",1)
      IF strParent=FIELD$(tstr,"|",6) THEN                    ' Is this a sibling?
        sibResult=sibResult+STR$(i)+"|"                     ' Add its index to the list
      END IF
    END IF
  NEXT i

  siblEnd:
  Result=sibResult
  'call  AddClrString ("2798:sibResult="+(sibResult), 0, LogEdit)
END FUNCTION

'*****************************************
' Recursively called to delete parent/sibling chains
SUB DeleteThisChain(StartIdx AS integer) '!!!! <<<<<<<<<<<<<<<  необновленные процедуры
  DEFINT i, cnt, nxt
  DEFSTR tstr, sibString
  DEFLNG hWnd

  sibString=FillSiblingList(StartIdx)                             ' Get list of child object indices
  cnt=TALLY(sibString,"|")
  IF cnt>0 THEN
    FOR i=1 TO cnt                                              ' Loop all child objects
      nxt=VAL(FIELD$(sibString,"|",i))                        ' Get next object index
      tstr=FIELD$(AddedObjectList(nxt),"~",1)
      SELECT CASE FIELD$(tstr,"|",2)
      CASE "QPANEL","QTABCONTROL","QGROUPBOX","QSCROLLBOX"    ' Not deleted ATT (may have siblings)
      CASE ELSE
        hWnd=VAL(FIELD$(tstr,"|",3))
        ShowWindow(hWnd,0)                              ' Delete the object
        AddedObjectList(nxt)=""
      END SELECT
    NEXT i
    FOR i=1 TO cnt                                              ' Loop all "parent type" child objects
      nxt=VAL(FIELD$(sibString,"|",i))                        ' Get next object index
      tstr=FIELD$(AddedObjectList(nxt),"~",1)
      SELECT CASE FIELD$(tstr,"|",2)
      CASE "QPANEL","QTABCONTROL","QGROUPBOX","QSCROLLBOX"
        DeleteThisChain(nxt)                            ' Recursive call to self
      END SELECT
    NEXT i
  END IF
  tstr=FIELD$(AddedObjectList(StartIdx),"~",1)                         ' Delete the initial parent object
  hWnd=VAL(FIELD$(tstr,"|",3))
  ShowWindow(hWnd,0)
  AddedObjectList(StartIdx)=""
END SUB



'!*****************************************
' Update property (pField) with its new property value (vField) in PropertyGrid
SUB PropertyFieldUpdate(pField, vField ) '!!! Update PropertyGrid from any source
  'call  AddClrString ("1075:PropertyFieldUpdate="+pField+" "+vField, subclr, LogEdit)
  ' pField - property name ie Top, Align, Color etc
  ' vField - property  value as string
  defstr celli

  pField=trim$(lcase$(pField))
  ''call  AddClrString ("3865:PropertyFieldUpdate pField="+(pField), clred, LogEdit)

  DEFSTR propString, token, tstr, resString ,objtype$
  DEFINT i, j, k, cnt
  propString=""

  For rowi=1 to PropertyGrid.RowCount-1
    celli=trim$(lcase$(PropertyGrid.Cell(0, rowi))) '  Caption, Top etc
    'call  AddClrString ("2864:PropertyGrid.Cell(0,"+ str$(rowi)+")="+(PropertyGrid.Cell(0, rowi)), cldr, LogEdit)
    'call  AddClrString ("2864:PropertyGrid.Cell(1,"+ str$(rowi)+")="+(PropertyGrid.Cell(1, rowi)), clm, LogEdit)

    if pField=celli   then
      'call  AddClrString ("2866:pField="+(pField), cla, LogEdit)
      'call  AddClrString ("2866:celli="+(celli), clp, LogEdit)
      if pField="color" then
        call  AddClrString ("3871:celli="+(celli), cldb, LogEdit)
        call  AddClrString ("3877:vField="+(vField), cldg, LogEdit)


      end if
      propString=vField
      PropertyGrid.Cell(1, rowi)=propString

      'PropertyGrid.Cell(1, rowi)=vField
      EXIT FOR
    end if

  next rowi

  'PropertyValueUpdate ' update cont alias to value

END SUB



'*****************************************
' Update AddedObjectList property (pField) with its new property value (vField) in string position
SUB PropertyFieldUpdate_OLD(pField AS string, vField AS string, position AS integer)
  'call  AddClrString ("1075:PropertyFieldUpdate="+str$(PropertyFieldUpdate), clg, LogEdit)
  DEFSTR propString, token, tstr, resString ,objtype$
  DEFINT i, j, k, cnt

  propString=AddedObjectList(CurrentObject)
  'call  AddClrString ("835:propString="+(propString), cldg, LogEdit)
  'propString=1|QEDIT|5900606|Edit4|Edit4|8389856~Left|INTEGER|RW|~Top|INTEGER|RW|~Width|INTEGER|RW|100~Height|INTEGER|RW|25~Align|INTEGER|RW|alNone|alNone|alTop|alBottom|alLeft|alRight|alClient
  '~AutoSize|INTEGER|RW|True|False|True~BorderStyle|INTEGER|RW|bsSingle|bsNone|bsSingle~CharCase|INTEGER|RW|ecNormal|ecNormal|ecUpperCase|ecLowerCase
  '~Color|INTEGER|RW|<default>|<default>|<choose>~EditText|STRING|RW|~Enabled|INTEGER|RW|True|False|True~Font|QFONT|R|<default>~Handle|LONG|R|~Hint|STRING|RW|~InputMask|STRING|RW|
  '~IsMasked|INTEGER|RW|False|False|True~MaxLength|INTEGER|RW|0~Modified|INTEGER|RW|~Parent|QFORM/QPANEL/QTABCONTROL|R|~PasswordChar|STRING|RW|~PopupMenu|QPOPUPMENU|W|
  '~ReadOnly|INTEGER|RW|False|False|True~SelLength|INTEGER|RW|~SelStart|INTEGER|RW|~SelText|STRING|RW|~ShowHint|INTEGER|RW|False|False|True~TabOrder|INTEGER|RW|~Tag|INTEGER|RW|
  '~Text|STRING|RW|~Visible|INTEGER|RW|True|False|True~* Methods~* Events~OnChange|| ~OnKeyDown||(Key AS WORD, Shift AS INTEGER)~OnKeyPress||(Key AS BYTE)~OnKeyUp||(Key AS WORD, Shift AS INTEGER)~

  objtype$=FIELD$(propString,"|",2)
  'call  AddClrString ("823:objtype="+(objtype$), cldp, LogEdit)

  cnt=TALLY(propString,"~"):

  resString=""
  FOR i=1 TO cnt
    token=FIELD$(propString,"~",i)
    IF FIELD$(token,"|",1)=pField THEN          ' Found this property string                     '
      'PropertyFieldUpdate("Left",STR$(tPoint.x),4)

      k=TALLY(token,"|")+1
      tstr=""
      FOR j=1 TO k
        IF j=position THEN                                  ' This value replaced
          tstr=tstr+vField+"|"
        ELSE
          tstr=tstr+FIELD$(token,"|",j)+"|"
        END IF
      NEXT j
      token=LEFT$(tstr,LEN(tstr)-1)                           ' Remove trailing "|"
    END IF
    resString=resString+token+"~"
  NEXT i
  'call  AddClrString ("1079:i="+str$(i), clred, LogEdit)
  AddedObjectList(CurrentObject)=resString                             ' Update the global properties string
  'call  AddClrString ("1081:CurrentObject="+str$(CurrentObject), clred, LogEdit)
  'PropertyValueUpdate

END SUB


'!!! ************** 2021 - обновляет поле value - численное значение define или const, например alTop = 1
sub PropertyValueUpdate
  'call  AddClrString ("4234:PropertyValueUpdate alias", subclr, LogEdit)
  ' there are integer value for property alias , for example bsSingle = 1 bsSingle - alias,
  '1 - value
  ' this procedure read property alias, search it's value in the PropertyList and set value in
  'hidden PropertyGrid cell - col=2

  defint rowi, ci
  defstr celli,PropVal$
  defstr const_i

  ''call  AddClrString ("4266:PropertyGrid.RowCount="+str$(PropertyGrid.RowCount), clred, LogEdit)

  For rowi=1 to PropertyGrid.RowCount-1
    PropVal$=trim$(lcase$(PropertyGrid.Cell(1, rowi))) ' bsSingle
    if  trim$(PropVal$)<>""  then
      ''call  AddClrString ("911:PropVal$="+(PropVal$), clred, LogEdit)
    end if

    PropertyGrid.Cell(2, rowi)="" ' предварительно очищаем ячейку алиаса

    for ci=0 to PropertyList.ItemCount-1 ' contain const name and value ie CONST bsSingle = 1

      alias$=trim$(lcase$(field$(PropertyList.Item(ci),"=",1)-"CONST" )) 'bsSingle
      call DelComments(@alias$)
      ''call  AddClrString ("4269:alias$="+(alias$), clm, LogEdit)
      'CONST clA=&hffff00
      if alias$=PropVal$ and trim$(alias$)<>""  then

        ''call  AddClrString ("922:alias$="+(alias$), cldb, LogEdit)
        aliasVal$=PropertyList.Item(ci)-" "
        aliasVal$=field$(PropertyList.Item(ci),"=",2)
        call DelComments(@aliasVal$)
        aliasVal$=trim$(aliasVal$)

        ''call  AddClrString ("4274:PropertyList.Item("+str$(ci)+")="+(PropertyList.Item(ci)), clred, LogEdit)
        ''call  AddClrString ("4273:aliasVal$="+(aliasVal$), clred, LogEdit)
        PropertyGrid.Cell(2, rowi)=aliasVal$'field$(PropertyList.Item(ci)," ",4) ' 1
        EXIT FOR
      end if

    next ci
  next rowi

  'GridFileName$=projectDir$+"\"+trim$(PropertyGrid.Cell(0,1))+".dat"
  GridFileName$=projectDir$+"\"+trim$(ObjectName(ObjectIndex))+".dat"
  'call  AddClrString ("5243:PropertyValueUpdate save GridFileName$="+(GridFileName$), cldr, LogEdit)
  PropertyGrid.SaveToFile(GridFileName$,0,0,PropertyGrid.RowCount)


end sub


'!!! ***************************************** 2021 - обновляет поле value - численное значение define или const, например alTop = 1
sub PropertyValueUpdate_Old
  defint rowi, ci
  defstr celli
  defstr const_i

  'call  AddClrString ("911:PropertyGrid.RowCount="+str$(PropertyGrid.RowCount), clred, LogEdit)

  For rowi=1 to PropertyGrid.RowCount-1
    celli=trim$(lcase$(PropertyGrid.Cell(1, rowi)))
    if  trim$(celli)<>""  then
      'call  AddClrString ("911:celli="+(celli), clred, LogEdit)
    end if

    for ci=0 to PropertyList.ItemCount-1

      const_i=trim$(lcase$(field$(PropertyList.Item(ci)," ",2)))

      if const_i=celli and trim$(const_i)<>""  then
        'call  AddClrString ("922:const_i="+(const_i), cldb, LogEdit)
        PropertyGrid.Cell(2, rowi)=field$(PropertyList.Item(ci)," ",4)
        EXIT FOR
      end if

    next ci
  next rowi



end sub


'--------------------- Editing objects visually ----------------------------------------
SUB RefreshObject(hWnd AS long, nuRect AS QRECT)
  call  AddClrString ("1155:RefreshObject hWnd="+str$(hWnd), subclr, LogEdit)
  ''call  AddClrString ("3913:nuRect.Left="+str$(nuRect.Left), clred, LogEdit)


  DEFINT Width, Height,objIndex
  DEFLNG Parnt
  DIM tPoint AS PointAPI


  Width=nuRect.Right-nuRect.Left
  Height=nuRect.Bottom-nuRect.Top
  tPoint.x=nuRect.Left: tPoint.y=nuRect.Top
  Parnt=GetParent(hWnd)
  ScreenToClient(Parnt,tPoint)

  PropertyFieldUpdate("Left", STR$(tPoint.x))
  PropertyFieldUpdate("Top", STR$(tPoint.y))
  PropertyFieldUpdate("Width", STR$(Width))
  PropertyFieldUpdate("Height", STR$(Height))

  reposn=1

  ObjectIndex=HandleToIndex(hWnd)
  'call  AddClrString ("5013:RefreshObject ObjectIndex="+str$(ObjectIndex), clm, LogEdit)
  'OblectName(ObjectIndex)

  SetWindowPos(hWnd, 0, tPoint.x, tPoint.y, Width, Height, SW_FLAGS)

  '!GridFileName$=projectDir$+"\"+trim$(PropertyGrid.Cell(0,1))+".dat"
  GridFileName$=projectDir$+"\"+trim$(ObjectName(ObjectIndex))+".dat"

  call  AddClrString ("5013:RefreshObject GridFileName$="+(GridFileName$), cldp, LogEdit)
  'call  AddClrString ("5146:PropertyValueUpdate save GridFileName$="+(GridFileName$), cldr, LogEdit)
  PropertyGrid.SaveToFile(GridFileName$,0,0,PropertyGrid.RowCount)


END SUB


'*****************************************
'--------------------- Editing objects visually ----------------------------------------
SUB RefreshObject_OLD(hWnd AS long, nuRect AS QRECT)
  'call  AddClrString ("1155:RefreshObject=", clg, LogEdit)
  DEFINT Width, Height
  DEFLNG Parnt
  DIM tPoint AS PointAPI

  Width=nuRect.Right-nuRect.Left
  Height=nuRect.Bottom-nuRect.Top
  tPoint.x=nuRect.Left: tPoint.y=nuRect.Top
  Parnt=GetParent(hWnd)
  ScreenToClient(Parnt,tPoint)

  'PropertyFieldUpdate("Left", STR$(tPoint.x),4)
  'PropertyFieldUpdate("Top", STR$(tPoint.y),4)
  'PropertyFieldUpdate("Width", STR$(Width),4)
  'PropertyFieldUpdate("Height", STR$(Height),4)
  UpdatePropGrid(CurrentObject)
  'PropertyValueUpdate
  ReDrawComponent
  BuildFormCode

END SUB

'*****************************************
SUB AlignObject '!!!! <<< необновленные процедуры
  call  AddClrString ("1179:AlignObject="+str$(AlignObject), clred, LogEdit)
  DEFINT i, Top, Left, deltaX, deltaY
  DEFSTR tstr, propStr

  HideCarets                                                      ' If visible
  tstr=AddedObjectList(CurrentObject)                                  ' Component global string data
  FOR i=1 TO TALLY(tstr,"~")                                      ' For each property this component
    propStr=FIELD$(tstr,"~",i)
    SELECT CASE FIELD$(propStr,"|",1)                           ' Get current left/top values
    CASE "Left": Left=VAL(FIELD$(propStr,"|",4))
    CASE "Top": Top=VAL(FIELD$(propStr,"|",4))
    END SELECT
  NEXT i
  deltaX=(Left MOD 10): Left=Left-deltaX                          ' Adjust each value to grid
  IF deltaX>4 THEN Left=Left+10
  deltaY=(Top MOD 10): Top=Top-deltaY
  IF deltaY>4 THEN Top=Top+10

  'PropertyFieldUpdate("Left",STR$(Left),4)                        ' Update global string data
  'PropertyFieldUpdate("Top",STR$(Top),4)

  PropertyFieldUpdate("Left",STR$(Left))                        ' Update global string data
  PropertyFieldUpdate("Top",STR$(Top))

  'UpdatePropGrid(CurrentObject)                                   ' Update property grid fields
  'ReDrawComponent                                                 ' Redraw in new position
END SUB

'*****************************************
SUB MouseCopyObject '!!!! <<< необновленные процедуры
  DEFINT i
  DEFSTR tstr

  tstr=FIELD$(AddedObjectList(ObjectIndex),"~",1)                    ' Get the objectID of this component
  designMenu.Tag=VAL(FIELD$(tstr,"|",1))                          ' Store the ObjectID in the Tag property
  IF designMenu.Tag>0 THEN                                        ' NOT Forms (ID=0)!
    FOR i=0 TO MAX_FORMS'-1
      Forms(i).Cursor=crDrag                                  ' Show we are copying
    NEXT i
  END IF
END SUB

'*****************************************
SUB MousePasteObject '!!!! <<< необновленные процедуры
  DEFINT i

  FOR i=0 TO MAX_FORMS
    Forms(i).Cursor=crDefault                                   ' Cursor back to default
  NEXT i
  IF designMenu.Tag>0 THEN                                        ' NOT Forms (ID=0)!
    NewObjectID=designMenu.Tag                                  '!!! The pre-set object we are adding
    designMenu.Tag=0                                            ' Re-set this flag
    SetCursorPos(MouseSaveX,MouseSaveY)                         ' Re-adjust for popup menu position
    MouseSaveX=0: MouseSaveY=0
    '!AddNewObject                                                ' Add the object to the active form
  END IF
END SUB

'*****************************************
SUB ReDrawNonVisibles '!!!! <<< необновленные процедуры
  DEFINT i, j, x, objType
  DEFLNG hWnd
  DEFSTR tstr

  IF NonVisCount=0 THEN EXIT SUB
  j=0
  FOR i=1 TO MAX_OBJECTS                                          ' Start at second object
    tstr=FIELD$(AddedObjectList(i),"~",1)
    IF tstr="" THEN EXIT FOR
    objType=VAL(FIELD$(tstr,"|",1))                             ' Object type
    IF objType>=NON_VISIBLE THEN
      hWnd=VAL(FIELD$(tstr,"|",3))
      x=j*32 + 5: INC j                                       ' Left property
      SetWindowPos(hWnd, 0, x, 16, 30, 30, SW_FLAGS)          ' Reposition object
    END IF
  NEXT i
END SUB

'*****************************************
' Currently forms cannot be deleted
SUB DeleteComponent '!!!! <<< необновленные процедуры
  DEFINT i, j, objType
  DEFLNG hWnd
  DEFSTR tstr

  IF CurrentObject=0 THEN                                         ' Just in case! NEVER the initial Form
    MessageBox("You cannot delete this form!","Delete Component",&h10)
    EXIT SUB
  END IF
  HideCarets                                                      ' Hide if visible

  tstr=FIELD$(AddedObjectList(CurrentObject),"~",1)                    ' Check for non-visible objects
  objType=VAL(FIELD$(tstr,"|",1))                                 ' Object type
  IF objType>=NON_VISIBLE THEN
    hwnd=VAL(FIELD$(tstr,"|",3))
    ShowWindow(hWnd,0)                                          ' Delete the object
    AddedObjectList(CurrentObject)=""
    IF NonVisCount>0 THEN DEC NonVisCount                       ' Should ALWAYS be >0 to get here (but safety)
  ELSE
    DeleteThisChain(CurrentObject)                              ' Deletes this object plus any siblings
  END IF

  i=CurrentObject
  FOR j=i+1 TO ObjectIndex
    IF AddedObjectList(j)<>"" THEN                                   ' Tidy the AddedObjectList()...
      AddedObjectList(i)=AddedObjectList(j)                             '...compacting all remaining objects
      AddedObjectList(j)=""
      INC i
    END IF
  NEXT j

  ' NB: Do this AFTER the AddedObjectList array has been tidied (above)!
  IF objType>=NON_VISIBLE THEN ReDrawNonVisibles

  ' Fix the select combobox
  SelectionCombo.Clear                                            ' Clear selection combo
  FOR i=0 TO MAX_OBJECTS                                          ' Rebuild selection combo
    tstr=AddedObjectList(i)
    IF tstr="" THEN EXIT FOR
    tstr=FIELD$(tstr,"~",1)
    SelectionCombo.AddItems FIELD$(tstr,"|",5)+" ["+FIELD$(tstr,"|",2)+"]"
  NEXT i
  ObjectIndex=i                                                   ' Update this

  hWnd=Forms(FormIndex).Handle                                  ' Set focus to the underlying form
  FOR i=0 TO ObjectIndex-1
    tstr=FIELD$(AddedObjectList(i),"~",1)
    IF hWnd=VAL(FIELD$(tstr,"|",3)) THEN
      CurrentObject=i                                         ' The NEW current object
      UpdatePropGrid(CurrentObject)
      EXIT FOR
    END IF
  NEXT i
END SUB

'*****************************************
SUB MouseResizeObject(hWnd)
  'all  AddClrString ("1312:MouseResizeObject="+str$(MouseResizeObject), clg, LogEdit)
  DEFINT OldX, OldY, DeltaX, DeltaY, ax,ay
  DIM ObjRect AS QRECT

  OldX=screen.MouseX: OldY=screen.MouseY
  'x=ObjRect.Left-screen.MouseX
  'all  AddClrString ("1319:ax="+str$(ax), cldb, LogEdit)
  'y=ObjRect.Top-screen.MouseY
  'all  AddClrString ("1321:ay="+str$(ay), cldr, LogEdit)

  GetWindowRect(hWnd,ObjRect)
  DO
    DeltaX=OldX-screen.MouseX: DeltaY=OldY-screen.MouseY
    'all  AddClrString ("1321:screen.MouseX="+str$(screen.MouseX), clred, LogEdit)
    'all  AddClrString ("1325:ObjRect.Left="+str$(ObjRect.Left), clred, LogEdit)
    IF DeltaX<>0 OR DeltaY<>0 THEN

      SELECT CASE ActiveCaret
      CASE 1: ObjRect.Left=screen.MouseX-1: ObjRect.Top=screen.MouseY-1
      CASE 2: ObjRect.Left=screen.MouseX-1
      CASE 3: ObjRect.Left=screen.MouseX-1: ObjRect.Bottom=screen.MouseY+1      ' 1 8 7
      CASE 4: ObjRect.Bottom=screen.MouseY+1                                      ' 2   6
      CASE 5: ObjRect.Right=screen.MouseX+1: ObjRect.Bottom=screen.MouseY+1         ' 3 4 5
      CASE 6: ObjRect.Right=screen.MouseX+1
      CASE 7: ObjRect.Right=screen.MouseX+1: ObjRect.Top=screen.MouseY-1
      CASE 8: ObjRect.Top=screen.MouseY-1

      END SELECT

      'SELECT CASE ActiveCaret
      'CASE 1: ObjRect.Left=screen.MouseX: ObjRect.Top=screen.MouseY
      'CASE 2: ObjRect.Left=screen.MouseX
      'CASE 3: ObjRect.Left=screen.MouseX: ObjRect.Bottom=screen.MouseY          ' 1 8 7
      'CASE 4: ObjRect.Bottom=screen.MouseY                                            ' 2   6
      'CASE 5: ObjRect.Right=screen.MouseX: ObjRect.Bottom=screen.MouseY        ' 3 4 5
      'CASE 6: ObjRect.Right=screen.MouseX
      'CASE 7: ObjRect.Right=screen.MouseX: ObjRect.Top=screen.MouseY
      'CASE 8: ObjRect.Top=screen.MouseY

      'brem 0
      'CASE 1: ObjRect.Left=ObjRect.Left-DeltaX: ObjRect.Top=ObjRect.Top-DeltaY
      'CASE 2: ObjRect.Left=ObjRect.Left-DeltaX
      'CASE 3: ObjRect.Left=ObjRect.Left-DeltaX: ObjRect.Bottom=ObjRect.Bottom-DeltaY          ' 1 8 7
      'CASE 4: ObjRect.Bottom=ObjRect.Bottom-DeltaY                                            ' 2   6
      'CASE 5: ObjRect.Right=ObjRect.Right-DeltaX: ObjRect.Bottom=ObjRect.Bottom-DeltaY        ' 3 4 5
      'CASE 6: ObjRect.Right=ObjRect.Right-DeltaX
      'CASE 7: ObjRect.Right=ObjRect.Right-DeltaX: ObjRect.Top=ObjRect.Top-DeltaY
      'CASE 8: ObjRect.Top=ObjRect.Top-DeltaY
      'erem
      'END SELECT


      ShowCarets(ObjRect)
      OldX=screen.MouseX: OldY=screen.MouseY
    END IF
    DoEvents
  LOOP UNTIL ReSizing=False                                       ' Finished re-sizing

  RefreshObject(hWnd,ObjRect)
END SUB

'*****************************************
SUB MouseMoveObject(hWnd)
  call  AddClrString ("1025:MouseMoveObject="+str$(hWnd), clg, LogEdit)
  DEFINT OldX, OldY, DeltaX, DeltaY,ax,ay, bx,by, ' bx,by - cootdinates inside ObjRect
  DEFINT i, saveX
  DEFSTR tstr
  DIM ObjRect AS QRECT

  GetWindowRect(hWnd,ObjRect)
  saveX=ObjRect.Top
  'call  AddClrString ("3280:saveX="+str$(saveX), clred, LogEdit)
  ShowCarets(ObjRect)
  'call  AddClrString ("1351:ShowCarets="+str$(ShowCarets), clred, LogEdit)
  OldX=screen.MouseX: OldY=screen.MouseY

  ax=ObjRect.Left-screen.MouseX
  ay=ObjRect.Top-screen.MouseY

  bx=ObjRect.Right-screen.MouseX
  by=ObjRect.Bottom-screen.MouseY

  DO
    DeltaX=OldX-screen.MouseX: DeltaY=OldY-screen.MouseY

    IF DeltaX<>0 OR DeltaY<>0 THEN
      'ObjRect.Left=ObjRect.Left-DeltaX
      'ObjRect.Right=ObjRect.Right-DeltaX
      'ObjRect.Top=ObjRect.Top-DeltaY
      'ObjRect.Bottom=ObjRect.Bottom-DeltaY

      ObjRect.Left=ax+screen.MouseX
      ObjRect.Right=bx+screen.MouseX
      ObjRect.Top=ay+screen.MouseY
      ObjRect.Bottom=by+screen.MouseY

      ShowCarets(ObjRect)
      OldX=screen.MouseX: OldY=screen.MouseY
    END IF
    DoEvents
  LOOP UNTIL gMouseBtns=0
  'call  AddClrString ("1367:gMouseBtns="+str$(gMouseBtns), clred, LogEdit)
  ' Finished moving object
  ' Fudge for QSPLITTER
  i=HandleToIndex(hWnd)
  IF i>0 THEN
    'tstr=AddedObjectList(i)
    'IF FIELD$(tstr,"|",2)="QSPLITTER" THEN
    'i=ObjRect.Bottom-ObjRect.Top+1               ' FIX our default splitter to top of form
    'ObjRect.Top=saveX: ObjRect.Bottom=saveX+i
    'END IF
  END IF
  RefreshObject(hWnd,ObjRect)
END SUB

'*****************************************
FUNCTION WhichFormIsActive(hWnd AS long) AS integer
  DEFINT i
  Result=0
  FOR i=0 TO MAX_FORMS
    IF hWnd=Forms(i).Handle THEN
      Result=i                                                ' Return index in Forms()
      EXIT FOR
    END IF
  NEXT i
END FUNCTION

'*****************************************
FUNCTION IsObjectNonVis(ObjIndex AS integer) AS integer '!!!! <<< необновленные процедуры
  DEFSTR tstr=FIELD$(AddedObjectList(ObjIndex),"~",1)

  Result=False
  IF VAL(FIELD$(tstr,"|",1))>=NON_VISIBLE THEN Result=True
END FUNCTION

'*****************************************
FUNCTION IsObjectAForm(ObjIndex AS integer) AS integer
  'DEFSTR tstr=FIELD$(AddedObjectList(ObjIndex),"~",1)
  'call  AddClrString ("1359:tstr="+(tstr), clred, LogEdit)

  Result=False
  'IF VAL(FIELD$(tstr,"|",1))=0 THEN Result=True
  if ucase$(ObjectType(ObjIndex))="QFORM" then Result=True

  'call  AddClrString ("1363:Result="+str$(Result), clred, LogEdit)

END FUNCTION


'*****************************************
' Right mouse click on a non-selected object
SUB ForceSelection(hWnd AS long)
  DEFINT i
  DIM ObjRect AS QRECT

  FOR i=1 TO 8
    Carets(i).Color=&hbf                                        ' Dk Red highlight - alert user to change
  NEXT i
  GetWindowRect(hWnd,ObjRect)
  ShowCarets(ObjRect)
  Sleep.MS 150                                                    ' Delay for user to see the change
  FOR i=1 TO 8
    Carets(i).Color=&h3f7f00                                    ' Back to original color
  NEXT i
END SUB

'*****************************************
FUNCTION IsObjectMovable_OLD(ObjIndex AS integer) AS integer
  call  AddClrString ("1428:IsObjectMovable=", clg, LogEdit)
  DEFINT id
  DEFSTR tstr=FIELD$(AddedObjectList(ObjIndex),"~",1)
  call  AddClrString ("1451:tstr="+(tstr), clred, LogEdit)

  Result=True
  ObjType=VAL(FIELD$(tstr,"|",1))
  call  AddClrString ("1455:ObjType="+str$(ObjType), clred, LogEdit)
  IF (ObjType=0) OR (ObjType>=NON_VISIBLE) THEN Result=False
END FUNCTION


'!*****************************************
FUNCTION IsObjectMovable(ObjIndex AS integer) AS integer
  'call  AddClrString ("2805:IsObjectMovable ObjIndex="+str$(ObjIndex), subclr, LogEdit)

  DEFINT id
  'DEFSTR tstr=FIELD$(AddedObjectList(ObjIndex),"~",1)

  Result=True
  'id=VAL(FIELD$(tstr,"|",1))
  'IF (objtype=0) OR (objtype>=NON_VISIBLE) THEN Result=False
  IF ObjVisible(ObjIndex)=0 THEN Result=False
  'call  AddClrString ("2814:ObjVisible("+str$(ObjIndex)+")="+str$(ObjVisible(ObjIndex)), clred, LogEdit)
  ''call  AddClrString ("2813:Result="+str$(Result), clred, LogEdit)

  ''call  AddClrString ("2811:IsObjectMovable objtype="+str$(objtype), cldp, LogEdit)

END FUNCTION


'*****************************************
SUB ResetObjInspectorTab
  call  AddClrString ("3389:ResetObjInspectorTab="+str$(ResetObjInspectorTab), clred, LogEdit)
  'FieldEdit.Visible=False: FieldBox.Visible=False                 ' Ensure these not visible
  'call  AddClrString ("1401:FieldEdit.Visible="+str$(FieldEdit.Visible), clred, LogEdit)
  'ObjInspectorTab.TabIndex=0: ObjInspectorTabChange
END SUB




'!*****************************************
SUB ScanMouse
  ''call  AddClrString ("1123:ScanMouse="+str$(ScanMouse), subclr, LogEdit)
  DEFLNG hWnd
  DEFINT ObjIndex
  DEFINT FrmIndex

  ScanTimer.Enabled=False

  hWnd=WindowFromPoint(Screen.MouseX, Screen.MouseY)
  StBarFrmDsg.Panel(5).Caption="hWnd="+Str$(hWnd)
  ObjIndex=HandleToIndex(hWnd)
  StBarFrmDsg.Panel(4).Caption="OverObjIndex="+Str$(ObjIndex)

  if ObjIndex<0 then
    'call  AddClrString ("2609:ObjIndex="+str$(ObjIndex), clred, LogEdit)
    ScanTimer.Enabled=True
    exit sub
  end if


  if IsObjectAForm(ObjIndex)>0 then
    FrmIndex=ObjTypeIndex(ObjIndex)
    StBarFrmDsg.Panel(0).Caption="FrmIndex="+str$(FrmIndex)
    ''call  AddClrString ("2174:FormIndex="+str$(FormIndex), clred, LogEdit)
  else

  end if


  IF ReSizing THEN                                                ' Global flag set by carets()
    'call  AddClrString ("1460:ReSizing="+str$(ReSizing), clred, LogEdit)
    StBarFrmDsg.Panel(3).Caption="L"
    StBarFrmDsg.Panel(0).Caption="Resizing "+FIELD$(AddedObjectList(ObjectIndex),"|",5)
    'hWnd=VAL(FIELD$(AddedObjectList(ObjectIndex),"|",3))
    hWnd=ObjectHandle(ObjectIndex)
    'call  AddClrString ("2193:in MouseResizeObject hWnd="+str$(hWnd), clred, LogEdit)


    MouseResizeObject(hWnd)                                     ' Do the resizing
    '!!! UpdateStatus

  ELSEIF gMouseBtns=LMOUSE_BTN THEN      '!! Place or Select an object
    ''call  AddClrString ("2048:gMouseBtns="+str$(gMouseBtns), clred, LogEdit)
    'call  AddClrString ("2634:LMOUSE_BTN="+str$(LMOUSE_BTN), clb, LogEdit)
    StBarFrmDsg.Panel(3).Caption="L"
    hWnd=WindowFromPoint(Screen.MouseX, Screen.MouseY)
    'call  AddClrString ("3574:hWnd="+str$(hWnd), clm, LogEdit)
    ObjectIndex=HandleToIndex(hWnd)
    ObjectHandle(ObjectIndex)=hWnd
    'call  AddClrString ("3577:LMOUSE_BTN ObjectIndex="+str$(ObjectIndex), clm, LogEdit)

    IF (ObjectIndex >= 0) AND (ObjectIndex <= MAX_OBJECTS) THEN       ' Design object or form?
      'BringWindowToTop(Forms(FormIndex).Handle)      '!!! In case (partially) hidden RapidQ2.inc
      'ResetObjInspectorTab
      ''call  AddClrString ("1475:ResetObjInspectorTab="+str$(ResetObjInspectorTab), subclr, LogEdit)
      'call  AddClrString ("3583:NewObjectID="+str$(NewObjectID), clred, LogEdit)

      IF NewObjectID>0 THEN  ' Adding a new object
        'call  AddClrString ("3586:NewObjectID="+str$(NewObjectID), clred, LogEdit)
        '!AddNewObject (0)' если добавляем компонент с палитры, то  родителя берем с места клика мышки
        FieldEdit.Visible=False
        FieldBox.Visible=False
        OldRow=-1

        AddNewObject (hWnd)' если добавляем компонент с палитры, то  родителя берем с места клика мышки
        'call  AddClrString ("3593:Scan Mouse AddNewObject="+str$(AddNewObject), clb, LogEdit)
        cmboxObj.Text=cmboxObj.Item(cmboxObj.ItemCount-1)
      ELSE

        'call  AddClrString ("3597:OldObjectIndex="+str$(OldObjectIndex), clb, LogEdit)
        'call  AddClrString ("3597:ObjectIndex="+str$(ObjectIndex), clb, LogEdit)

        IF ObjectIndex<>OldObjectIndex THEN ' !!! переключились на новый компонент. Сохранить таблицу!!!
          '!!! сохраняем таблицу
          if projectDir$="" then ' создаем новый проект
            'projectDir$=StartDir+projectpath$+"Newproject "+time$-":"
            projectDir$=projectpath$+"Newproject "+time$-":"
            'call  AddClrString ("3600:projectDir$="+(projectDir$), clred, LogEdit)
            if direxists(projectDir$)=0 then
              mkdir projectDir$
            end if
          end if

          'if OldRow>-1 then
          'PropertyGrid.Cell(OldCol,OldRow)=OldPv$
          'call  AddClrString ("3479:Scan Mouse OldPv$="+(OldPv$), clred, LogEdit)
          FieldEdit.Visible=0
          FieldBox.Visible=0
          'EditPropertyField(PropertyGrid.Col, PropertyGrid.Row, CanSelect, PropertyGrid)
          FieldEdit.Visible=False
          FieldBox.Visible=False
          OldRow=-1
          'call  AddClrString ("3539:ScanMouse  OldRow="+str$(OldRow), clred, LogEdit)

          'ReDrawComponentbyField '!!! <<<<<<<<<<<<<<<<<<<<<<<<

          'end if


          GridFileName$=projectDir$+"\"+trim$(field$(cmboxObj.text," ",1))+".dat"

          '!!! сохраняем таблицу OldObjectIndex компонента
          PropertyGrid.SaveToFile(GridFileName$,0,0,PropertyGrid.RowCount)
          'call  AddClrString ("2666:SaveToFile GridFileName$="+(GridFileName$), clred, LogEdit)

          OldObjectIndex=ObjectIndex    ' Set current object selected
          'call  AddClrString ("2671:ObjectIndex="+str$(ObjectIndex), cldb, LogEdit)

          if IsObjectAForm(ObjectIndex)>0 then
            FormIndex=ObjTypeIndex(ObjectIndex)
            'call  AddClrString ("2174:new FormIndex="+str$(FormIndex), cldb, LogEdit)
          else

          end if

          '!!!  переключаем cmboxObj
          cmboxObj.ItemIndex=ObjectIndex '!!!! Scanmouse !!!!!!!!!!!!!!!!!
          'call  AddClrString ("3564:ScanMouse ObjectIndex="+str$(ObjectIndex), clred, LogEdit)

          ' загружаем таблицу свойств нового компонента
          GridFileName$=projectDir$+"\"+trim$(field$(cmboxObj.text," ",1))+".dat"
          'call  AddClrString ("3568:Load GridFileName$="+(GridFileName$), clred, LogEdit)
          'PropertyGrid.RowCount=100
          'call  AddClrString ("3570:PropertyGrid.RowCount="+str$(PropertyGrid.RowCount), clred, LogEdit)

          for ri=1 to PropertyGrid.RowCount-1
            'call  AddClrString ("3573:ri="+str$(ri), clred, LogEdit)
            for cj=0 to PropertyGrid.ColCount-1
              PropertyGrid.Cell(cj,ri)=""
            next
          next

          for ri=1 to DefaultPropertyGrid.RowCount-1
            'call  AddClrString ("3573:ri="+str$(ri), clred, LogEdit)
            for cj=0 to DefaultPropertyGrid.ColCount-1
              DefaultPropertyGrid.Cell(cj,ri)=""
            next
          next

          ' PropertyGrid.RowCount=5
          'call  AddClrString ("3576:PropertyGrid.RowCount="+str$(PropertyGrid.RowCount), clred, LogEdit)

          objName$=ObjectName(ObjectIndex)'trim$(field$(cmboxObj.Item(cmboxObj.ItemIndex)," as ",1))
          objtype$=ObjectType(ObjectIndex)'trim$(field$(cmboxObj.Item(cmboxObj.ItemIndex)," as ",2))
          'objtype$=trim$(field$(objtype$)," ",1))

          ObjNameGrid.Cell(0,1)=ObjectName(ObjectIndex)
          ObjNameGrid.Cell(1,1)=ObjectType(ObjectIndex)

          'call  AddClrString ("3563:objtype$="+(objtype$), clred, LogEdit)

          'call  AddClrString ("2693: ScanMouse Загружаем из GridFileName$="+(GridFileName$), clred, LogEdit)
          PropertyGrid.LoadFromFile(GridFileName$,0,0,1000)
          'ObjNameGrid.Cell(0,1)=PropertyGrid.Cell(0,1)
          'ObjNameGrid.Cell(1,1)=PropertyGrid.Cell(1,1)
          'ObjNameGrid.Cell(2,1)=PropertyGrid.Cell(2,1)

          'DefGridFileName$=StartDir+"data\"+PropertyGrid.Cell(1,1)+".data"
          DefGridFileName$=StartDir+"data\"+ObjectType(ObjectIndex)+".data"

          'call  AddClrString ("3524:ScanMouse DefGridFileName$="+(DefGridFileName$), clm, LogEdit)
          'call  AddClrString ("2101:objtype$="+(ObjType(ObjectIndex)), clb, LogEdit)

          if fileexists (DefGridFileName$)>0 then
          else
            objtype$="qpanel" '"trim$(field$(objtype$," ",1))
            DefGridFileName$=StartDir+"data\"+objtype$+".data"
          end if
          DefaultPropertyGrid.LoadFromFile(DefGridFileName$,0,0,1000)


        END IF

        'IF IsObjectMovable(ObjectIndex) THEN
        IF ObjVisible(ObjectIndex)>0 THEN
          'call  AddClrString ("2213:ObjVisible("+str$(ObjectIndex)+")="+str$(ObjVisible(ObjectIndex)), clred, LogEdit)

          MouseMoveObject(hWnd) ' Not forms or non-visible objects - only carret moved
          'call  AddClrString ("1483:after MouseMoveObject="+str$(MouseMoveObject), subclr, LogEdit)

        ELSE
          HideCarets
          ''call  AddClrString ("1487:HideCarets="+str$(HideCarets), subclr, LogEdit)
        END IF

      END IF
    END IF

  ELSEIF gMouseBtns=RMOUSE_BTN THEN
    StBarFrmDsg.Panel(3).Caption="R"
    'ResetObjInspectorTab
    hWnd=WindowFromPoint(Screen.MouseX, Screen.MouseY)
    'call  AddClrString ("2722:RMOUSE_BTN WindowFromPoint hWnd="+str$(hWnd), 777, LogEdit)
    ObjectIndex=HandleToIndex(hWnd)
    'call  AddClrString ("2727:RMOUSE_BTN  ObjectIndex="+str$(ObjectIndex), cldg, LogEdit)
    IF (ObjectIndex >= 0) AND (ObjectIndex <= MAX_OBJECTS) THEN
      IF ObjectIndex<>ObjectIndex THEN
        ObjectIndex=ObjectIndex                              ' Set current object selected
        'UpdatePropGrid(ObjIndex)                            ' Fill in the property string grid
        IF ObjVisible(ObjectIndex)>0 THEN
          'ForceSelection(hWnd)                            ' Change current object
        END IF
      END IF
      HideCarets                                              ' If visible - hide in any case
      IF IsObjectAForm(ObjectIndex) THEN
        FormPopUp(Screen.MouseX, Screen.MouseY)
      ELSEIF IsObjectNonVis(ObjectIndex) THEN
        NonVisPopup(Screen.MouseX, Screen.MouseY)
      ELSE
        ObjPopUp(Screen.MouseX, Screen.MouseY)
      END IF
    END IF

  ELSEIF gMouseBtns=0 THEN ' !!! переписываем текущие координаты объекта в таблицу свойств
    'call  AddClrString ("2744:gMouseBtns="+str$(gMouseBtns), clred, LogEdit)

    if ReSizing=1 then
      ReSizing=0
      StBarFrmDsg.Panel(3).Caption=""
      goto exitSM:

    end if


    if StBarFrmDsg.Panel(3).Caption="L" then
      OldObjectIndex=ObjectIndex    ' Set current object
      'call  AddClrString ("3745:OldObjectIndex="+str$(OldObjectIndex), clred, LogEdit)

      if ObjIndex>-1 and ObjectIndex=ObjIndex then

        IF IsObjectAForm(ObjIndex) THEN
          'call  AddClrString ("2447:FormIndex="+str$(FormIndex), clo, LogEdit)
          ReSizeForm(Forms(FormIndex))
          'call  AddClrString ("2228:FormIndex="+str$(FormIndex), clo, LogEdit)
          StBarFrmDsg.Panel(3).Caption="Form position changed"
        else
          StBarFrmDsg.Panel(3).Caption=""
        END IF
      end if


    end if

  END IF

  exitSM:
  DoEvents

  ScanTimer.Enabled=True
  ''call  AddClrString ("1477:ScanTimer.Enabled="+str$(ScanTimer.Enabled), clred, LogEdit)
END SUB



'*****************************************
SUB ScanMouse_OLD
  'call  AddClrString ("1123:ScanMouse="+str$(ScanMouse), clg, LogEdit)
  DEFLNG hWnd
  DEFINT ObjIndex

  ScanTimer.Enabled=False
  'call  AddClrString ("1409:ScanTimer.Enabled="+str$(ScanTimer.Enabled), clred, LogEdit)
  hWnd=WindowFromPoint(Screen.MouseX, Screen.MouseY)
  ObjIndex=HandleToIndex(hWnd)
  'call  AddClrString ("1491:hWnd="+str$(hWnd), clred, LogEdit)
  'call  AddClrString ("1491:ObjIndex="+str$(ObjIndex), clred, LogEdit)

  if ObjIndex<0 then
    ScanTimer.Enabled=True
    exit sub
  end if

  IF ReSizing THEN                                                ' Global flag set by carets()
    'call  AddClrString ("1460:ReSizing="+str$(ReSizing), clred, LogEdit)
    stat.Panel(3).Caption="L"
    stat.Panel(0).Caption="Resizing "+FIELD$(AddedObjectList(CurrentObject),"|",5)
    hWnd=VAL(FIELD$(AddedObjectList(CurrentObject),"|",3))
    MouseResizeObject(hWnd)                                     ' Do the resizing
    UpdateStatus
  ELSEIF gMouseBtns=LMOUSE_BTN THEN                               ' Place or Select an object?
    stat.Panel(3).Caption="L"
    hWnd=WindowFromPoint(Screen.MouseX, Screen.MouseY)
    ObjIndex=HandleToIndex(hWnd)

    IF (ObjIndex >= 0) AND (ObjIndex <= MAX_OBJECTS) THEN       ' Design object or form?
      'BringWindowToTop(Forms(CurrentForm).Handle)             ' In case (partially) hidden
      ResetObjInspectorTab
      'call  AddClrString ("1475:ResetObjInspectorTab="+str$(ResetObjInspectorTab), clg, LogEdit)

      IF NewObjectID>0 THEN                                   ' Adding a new object?
        'AddNewObject
        'call  AddClrString ("1479:AddNewObject="+str$(AddNewObject), clb, LogEdit)
      ELSE

        IF ObjIndex<>CurrentObject THEN
          CurrentObject=ObjIndex                          ' Set current object selected
          'call  AddClrString ("1436:CurrentObject="+str$(CurrentObject), clred, LogEdit)
          'UpdatePropGrid(ObjIndex)                        ' Fill in the property string grid
        END IF

        IF IsObjectMovable(CurrentObject) THEN
          MouseMoveObject(hWnd)                           ' Not forms or non-visible objects - only carret moved
          'call  AddClrString ("1483:MouseMoveObject="+str$(MouseMoveObject), clg, LogEdit)
        ELSE
          HideCarets
          'call  AddClrString ("1487:HideCarets="+str$(HideCarets), clg, LogEdit)
        END IF

      END IF
    END IF

  ELSEIF gMouseBtns=RMOUSE_BTN THEN
    stat.Panel(3).Caption="R"
    ResetObjInspectorTab
    hWnd=WindowFromPoint(Screen.MouseX, Screen.MouseY)
    ObjIndex=HandleToIndex(hWnd)
    IF (ObjIndex >= 0) AND (ObjIndex <= MAX_OBJECTS) THEN
      IF ObjIndex<>CurrentObject THEN
        CurrentObject=ObjIndex                              ' Set current object selected
        UpdatePropGrid(ObjIndex)                            ' Fill in the property string grid
        IF IsObjectMovable(CurrentObject) THEN
          ForceSelection(hWnd)                            ' Change current object
        END IF
      END IF
      HideCarets                                              ' If visible - hide in any case
      IF IsObjectAForm(ObjIndex) THEN
        FormPopUp(Screen.MouseX, Screen.MouseY)
      ELSEIF IsObjectNonVis(ObjIndex) THEN
        NonVisPopup(Screen.MouseX, Screen.MouseY)
      ELSE
        ObjPopUp(Screen.MouseX, Screen.MouseY)
      END IF
    END IF
  ELSEIF gMouseBtns=0 THEN
    if stat.Panel(3).Caption="L" then
      if ObjIndex>-1 then
        IF IsObjectAForm(ObjIndex) THEN
          ReSizeForm(Forms(FormIndex))
          stat.Panel(3).Caption="Form position changed"
        else
          stat.Panel(3).Caption=""
        END IF
      end if
    end if

  END IF
  DoEvents
  ScanTimer.Enabled=True
  'call  AddClrString ("1477:ScanTimer.Enabled="+str$(ScanTimer.Enabled), clred, LogEdit)
END SUB

'-------------------- Carets used while editing -------------------------------------
'*****************************************
SUB CaretMseDown(MouseButton,X,Y,Shift,Sender)
  ActiveCaret=Sender.Tag: ReSizing=True
END SUB

'*****************************************
SUB CaretMseUp(MouseButton,X,Y,Shift,Sender)
  ActiveCaret=0: ReSizing=False
END SUB

'*****************************************
SUB ShowCarets(tgtRect)
  DIM tPoint AS PointAPI
  DEFINT i, Left, Top, Width, Height
  DEFINT midX, midY

  tPoint.x=tgtRect.Left: tPoint.y=tgtRect.Top
  ''call  AddClrString ("2332:tgtRect.Top="+str$(tgtRect.Top), clred, LogEdit)
  ''call  AddClrString ("2332:tgtRect.Left="+str$(tgtRect.Left), clred, LogEdit)
  ScreenToClient(Forms(FormIndex).Handle, tPoint)
  Left=tPoint.x: Top=tPoint.y

  Width=tgtRect.Right-tgtRect.Left
  Height=tgtRect.Bottom-tgtRect.Top
  midX=Width\2-3: midY=Height\2-3

  brem 0
  ======
  Carets(1).Top=Top-6: Carets(1).Left=Left-6: Carets(1).Visible=True
  Carets(2).Top=Top+midY: Carets(2).Left=Left-6: Carets(2).Visible=True             ' Carets 6x6 pixels
  Carets(3).Top=Top+Height: Carets(3).Left=Left-6: Carets(3).Visible=True           '     1   8   7
  Carets(4).Top=Top+Height: Carets(4).Left=Left+midX: Carets(4).Visible=True        '     2       6
  Carets(5).Top=Top+Height: Carets(5).Left=Left+Width-6: Carets(5).Visible=True       '     3   4   5
  Carets(6).Top=Top+midY: Carets(6).Left=Left+Width-6: Carets(6).Visible=True
  Carets(7).Top=Top-6: Carets(7).Left=Left+Width-6: Carets(7).Visible=True
  Carets(8).Top=Top-6: Carets(8).Left=Left+midX: Carets(8).Visible=True
  erem

  Carets(1).Top=Top: Carets(1).Left=Left: Carets(1).Visible=True
  Carets(2).Top=Top+midY: Carets(2).Left=Left: Carets(2).Visible=True             ' Carets 6x6 pixels
  Carets(3).Top=Top+Height-6: Carets(3).Left=Left: Carets(3).Visible=True           '     1   8   7
  Carets(4).Top=Top+Height-6: Carets(4).Left=Left+midX: Carets(4).Visible=True        '     2       6
  Carets(5).Top=Top+Height-6: Carets(5).Left=Left+Width-6: Carets(5).Visible=True       '     3   4   5
  Carets(6).Top=Top+midY: Carets(6).Left=Left+Width-6: Carets(6).Visible=True
  Carets(7).Top=Top: Carets(7).Left=Left+Width-6: Carets(7).Visible=True
  Carets(8).Top=Top: Carets(8).Left=Left+midX: Carets(8).Visible=True

  CaretsTimer.Enabled=True                                        ' Ensure this is running
END SUB

'*****************************************
SUB HideCarets
  DEFINT i

  CaretsTimer.Enabled=False
  FOR i=1 TO 8
    Carets(i).Visible=False
  NEXT i
  ActiveCaret=0
END SUB

'*****************************************
SUB CaretsOnTop
  DEFINT i

  FOR i=1 TO 8
    SetWindowPos(Carets(i).Handle,0,0,0,0,0,FLAGS)
  NEXT i
END SUB

'--------------------- General subs/fns ------------------------------------------
'---------------------------------------------------------------------------------
'*****************************************
' Height of Active TitleBar - (Form.Height-Form.ClientHeight-2*Border-1)
SUB GetThemeOffset()'!!!! <<< необновленные процедуры
  DEFINT h1,h2,w1,w2,TwoBrdr

  h1=Forms(1).Height: w1=Forms(1).Width
  h2=Forms(1).ClientHeight: w2=Forms(1).ClientWidth
  TwoBrdr=w1-w2
  ThemeOffsetY = (h1-h2-TwoBrdr-1) - 18                           ' Windows Classic TitleBar Height=18
END SUB

'*****************************************
SUB Initialise
  DEFSTR tstr
  DEFINT i, wStyle, ci
  DEFINT curs(1 TO 8)={-8, -9, -6, -7, -8, -9, -6, -7}                ' Cursors for caret movement

  SetWindowLong(MainForm.Handle, -8, 0)                           ' MainForm minimize correctly
  SetWindowLong(Application.Handle, -8, MainForm.Handle)

  ComponentRef.ExtractRes(Resource(0))      ' Load all component text data
  ComponentRef.Position=0                   ' Initialise component reference source
  tstr=UCASE$(ComponentRef.ReadLine)        ' Read top line (QFORM...)
  IF INSTR(tstr,"RAPIDQ")>0 THEN
    MOD_ComponentForm.Caption="RapidQ Component Support"
  ELSE
    MOD_ComponentForm.Caption="FreeBASIC Component Support"
  END IF

  HelpRef.Position=0                                              ' Initialise the help reference stream
  HelpRef.ExtractRes(Resource(1))                                 ' Load the help text data

  LoadSingleButtons                                               ' Set the individual buttons
  LoadToolBarHints                                                ' Set the toolbar hints
  NonVisBMP.Width=27                                              ' Holds selected non-visible bmp
  NonVisBMP.Height=27
  DesignTab.TabIndex=0
  DesignTabChange

  FOR i=0 TO MAX_FORMS
    'wStyle=GetWindowLong(Forms(i).Handle, GWL_STYLE)
    'SetWindowLong(Forms(i).Handle, GWL_STYLE, (wStyle OR WS_CHILD)) ' set CHILD style for window
    'SetParent(Forms(i).Handle, FormsPanel.Handle)
    'SetParent(Forms(i).Handle, DesignPan.Handle) ' DesignPan as parent for Forms(i)

    'Forms(i).Left=0
    'Forms(i).Top=0
    'Forms(i).Caption="Form"+STR$(i)
    'Forms(i).Visible=False
    'Forms(i).AutoScroll=False                                   ' NOT default - but problems if changed
    'Forms(i).IcoHandle=BlankIco
    'Forms(i).OnPaint=PaintFormGrid
    'Forms(i).OnResize=ReSizeForm
    'Forms(i).OnMouseMove=FormsOnMouseMove
    'Forms(i).OnClose=NoClose
    'Forms(i).PopUpMenu=designMenu


    Forms(i).Left=0
    Forms(i).Top=0
    Forms(i).Width=320
    Forms(i).Height=250
    Forms(i).Caption="Form"+STR$(i)
    Forms(i).Visible=False
    Forms(i).AutoScroll=False                                   ' NOT default - but problems if changed
    Forms(i).IcoHandle=BlankIco
    Forms(i).OnPaint=PaintFormGrid
    Forms(i).PopUpMenu=designMenu
    'Forms(i).center
    Forms(i).Parent=MainForm
    Forms(i).Caption="Main Form "+str$(i)
    Forms(i).OnResize=ReSizeForm
    Forms(i).OnMouseMove=FormsOnMouseMove
    Forms(i).OnClose=NoClose
    Forms(i).FormStyle = fsStayOnTop




  NEXT i
  Forms(1).Caption="Main Form"
  'GetThemeOffset()                                                ' X offset from Windows Classic theme

  ColorPick.Style=cdFullOpen                                      ' Initialise the color chooser window
  ColorPick.Left=ObjInspectorPan.Left-ColorPick.Width
  ColorPick.Top=(Screen.Height-ColorPick.Height)\2
  ColorPick.height=400
  FwdDeclares=" ": FormsList=" ": KnownsList=" "                  ' Initialise the global string data
  MainMenuList=" ": PopMenuList=" ": UnknownList=" "

  'FrmIndex=1: ObjectIndex=0: ComponentCount=0  'FrmIndex=1 - эта форма становится видимой при инициализации

  'IF FindHelpFile THEN mnuHelp.Enabled=True

  FOR i=1 TO 8
    Carets(i).Tag=i
    Carets(i).Height=6: Carets(i).Width=6
    Carets(i).Cursor=curs(i): Carets(i).Color=&h3f7f00
    Carets(i).Visible=False
    Carets(i).OnMouseDown=CaretMseDown
    Carets(i).OnMouseUp=CaretMseUp
  NEXT i

  ActiveCaret=0                                                   ' Used for re-positioning/re-scaling
  CaretsTimer.Interval=250
  CaretsTimer.Enabled=False
  CaretsTimer.OnTimer=CaretsOnTop                                 ' Keeps carets visible when needed

  ScanTimer.Interval=50
  ScanTimer.Enabled=False
  ScanTimer.OnTimer=ScanMouse                                          ' Main loop in design form

  HookTheMouse()                                                  ' In RapidFRM.inc
  'call  AddClrString ("1466:CommandCount="+str$(CommandCount), clred, LogEdit)


  '!!! добавить автозагрузку последнего проекта
  brem 0
  ========================
  ===========
  erem

  ProjectFile=LTRIM$(RTRIM$(COMMAND$(1)))
  call  AddClrString ("4167:ProjectFile="+(ProjectFile), 0, LogEdit)

  'IF CommandCount=0 THEN                                          ' New project?
  IF ProjectFile="" or fileexists(ProjectFile)=0 THEN                                          ' New project?

    ProjectMode=STAND_ALONE
    call  AddClrString ("4168:ProjectMode="+str$(ProjectMode), clred, LogEdit)
    edPsave.Enabled=False                                       ' Fix the popup menu
    MainForm.Caption=MainForm.Caption+"    [New project]"
    'AddNewForm                                                  ' Add an initial form
    'INC ComponentCount
  ELSE                                                            ' Editing an existing project?
    ProjectFile=LTRIM$(RTRIM$(COMMAND$(1)))
    call  AddClrString ("4175:COMMAND$(0)="+(COMMAND$(0)), clred, LogEdit)
    call  AddClrString ("4175:COMMAND$(1)="+(COMMAND$(1)), clred, LogEdit)
    call  AddClrString ("4175:COMMAND$(2)="+(COMMAND$(2)), clred, LogEdit)
    call  AddClrString ("4175:COMMAND$(3)="+(COMMAND$(3)), clred, LogEdit)
    call  AddClrString ("4175:COMMAND$(4)="+(COMMAND$(4)), clred, LogEdit)
    call  AddClrString ("4175:COMMAND$(5)="+(COMMAND$(5)), clred, LogEdit)
    call  AddClrString ("4175:COMMAND$(6)="+(COMMAND$(6)), clred, LogEdit)
    call  AddClrString ("1473:ProjectFile="+(ProjectFile), clred, LogEdit)

    if fileexists(ProjectFile)=0 then Showmessage("4189:ProjectFile="+ProjectFile+" not found" )
    IF UCASE$(ProjectFile)="CLIPBOARD" THEN
      MainForm.Caption=MainForm.Caption+"    [Input clipboard]"
      ProjectMode=INPUT_CLIPBRD                               ' Read the clipboard for input
    ELSE
      '!!! загружаем  файл исходника
      MainForm.Caption=MainForm.Caption+"    [Input "+ProjectFile+"]"
      ProjectMode=INPUT_FILE                                  ' Read a file for input
    END IF

    edCopy.Enabled=False                                        '|
    partCopy.Enabled=False                                      '| Fix the popup menu
    tplSave.Enabled=True                                        '|
    edSave.Enabled=False                                        '|
    LoadProject                                                 ' Load and parse the project code
    ' NB NEED to wait until AFTER MainForm is showing B4 we can start DISPLAYING components.
    DelayTimer.Interval=200                                     ' Set a delay of 200 mSecs
    DelayTimer.Enabled=True
    DelayTimer.OnTimer=ShowProject                              ' Allow time for initial screen paint
  END IF
  'MOD_ComponentForm.Show

  ' read global data into RQGlobalGrid
  ComponentRef.Position=0                                         ' Stream contains default data ALL components
  RQCompGlobalGrid.RowCount=ComponentRef.LineCount

  FOR i=1 TO ComponentRef.LineCount
    tstr=ComponentRef.Readline
    RQCompGlobalGrid.cell(8,i)=str$(i)
    IF instr(tstr,"#")>0 THEN ' component name
      inc ci
      RQCompGlobalGrid.cell(0,i)=field$(tstr," ",3)
      RQCompGlobalGrid.cell(1,i)=str$(ci)

    elseIF instr(tstr,"||")>0 THEN ' properties
      RQCompGlobalGrid.cell(1,i)=tstr 'field$(tstr,"|",3)
      RQCompGlobalGrid.cell(2,i)=field$(tstr,"||",1) 'Name
      RQCompGlobalGrid.cell(5,i)=field$(tstr,"||",2) 'Name



    elseIF instr(tstr,"|")>0 THEN ' properties
      RQCompGlobalGrid.cell(1,i)=tstr 'field$(tstr,"|",3)  AutoScroll|INTEGER|RW|True|False|True
      RQCompGlobalGrid.cell(2,i)=field$(tstr,"|",1) 'Name
      RQCompGlobalGrid.cell(3,i)=field$(tstr,"|",3) 'R/W
      RQCompGlobalGrid.cell(4,i)=field$(tstr,"|",4) 'Default
      RQCompGlobalGrid.cell(6,i)=field$(tstr,"|",2) 'Type
      RQCompGlobalGrid.cell(7,i)=""'field$(tstr,"|",4) 'Support
      if tally(tstr,"|")>4 then


        'b% = INSTR(1, tstr, "|") '-- returns 7
        'b% = INSTR(b%+1, tstr, "|") '-- returns 7
        'b% = INSTR(b%+1, tstr, "|") '-- returns 7
        'b% = INSTR(b%+1, tstr, "|") '-- returns 7

        b% =0
        for J%=1 to 4
          b% = INSTR(b%+1, tstr, "|") '-- returns 7
        next


        e%=len(tstr)
        list$=mid$(tstr,b%+1,e%-b%+1)
        RQCompGlobalGrid.cell(5,i)=list$
      end if

      '835:propString=2|QRICHEDIT|9241732|RichEd1|RichEd1|6686328~Left|INTEGER|RW|61~Top|INTEGER|RW|35~Width|INTEGER|RW|200~Height|INTEGER|RW|100
      '!!! ~Align|INTEGER|RW| alNone| alNone|alTop|alBottom|alLeft|alRight|alClient
      '~Alignment|INTEGER|RW|taLeftJustify|taLeftJustify|taRightJustify|taCenter~BorderStyle|INTEGER|RW|bsSingle|bsNone|bsSingle~Color|INTEGER|RW|<default>|<default>|<choose color>~Enabled|INTEGER|RW|True|False|True~Font|QFONT|W|<default>|<default>|<choose font>~Handle|LONG|R|~HideScrollBars|INTEGER|RW|True|False|True~HideSelection|INTEGER|RW|True|False|True~Hint|STRING|RW|~Line|ARRAY of STRING|RW|~LineCount|INTEGER|RW|~Modified|INTEGER|R|~Parent|QFORM/QPANEL/QTABCONTROL|R|Form1~PopupMenu|QPOPUPMENU|W|~Plaintext|INTEGER|RW|False|False|True~Readonly|INTEGER|RW|False|False|True~ScrollBars|INTEGER|RW|ssNone|ssNone|ssHorizontal|ssVertical|ssBoth~SelAttributes|QFONT|W|<default>~SelLength|INTEGER|RW|~SelStart|INTEGER|RW|~SelText|STRING|RW|~ShowHint|INTEGER|RW|False|False|True~TabOrder|INTEGER|RW|~Tag|INTEGER|RW|~Text|STRING|RW|~Visible|INTEGER|RW|True|False|True~WantTabs|INTEGER|RW|False|False|True~WhereX|INTEGER|R|~WhereY|INTEGER|R|~Wordwrap|INTEGER|RW|True|False|True~* Methods~* Events~OnChange||~OnKeyDown||(Key AS WORD, Shift AS INTEGER)~OnKeyPress||(Key AS BYTE)~OnKeyUp||(Key AS WORD, Shift AS INTEGER)~OnMouseDown||(Button AS INTEGER, X AS INTEGER, Y AS INTEGER, Shift AS INTEGER)~OnMouseMove||(X AS INTEGER, Y AS INTEGER, Shift AS INTEGER)~OnMouseUp||(Button AS INTEGER, X AS INTEGER, Y AS INTEGER, Shift AS INTEGER)~
      'AutoScroll|INTEGER|RW|True|False|True
      'b% = INSTR(4, tstr, "|") '-- returns 7
      'e%=len(tstr)
      'list$=mid$(tstr,b%,e%-b%)

    END IF

  NEXT i

  RQCompGlobalGrid.savetofile("data\RQCompGlobalGrid.data",0,0,1000)

  ' создаем и сохраняем файлы данных по компонентам
  'dim tmtpgrid as qstringgrid
  'SUB (File$, RowOffset%, ColOffset%, MaxRows%) RowOffset - начальная строка,  MaxRows% - последняя строка

  k%=0
  for i=1 to RQCompGlobalGrid.RowCount-1

    if RQCompGlobalGrid.cell(0,i)<> "" then
      if k%>0 then
        'call  AddClrString ("1690:k%="+str$(k%), clred, LogEdit)
        'call  AddClrString ("1692:i="+str$(i), clred, LogEdit)
        'call  AddClrString ("1690:RQCompName$="+(RQCompName$), cldb, LogEdit)
        '!RQCompGlobalGrid.savetofile("data\"+RQCompName$+".data",k%+1,2,i-1)
        'sleep 10
        RQCompName$=RQCompGlobalGrid.cell(0,i)

        k%=i
      else
        RQCompName$=RQCompGlobalGrid.cell(0,i)
        inc k%
      end if
    end if
  next i

  PropertyGrid.Repaint

END SUB

'*****************************************
FUNCTION GetScreenHeight() AS integer
  DEFINT rct(0 TO 3)

  SystemParametersInfo(48, 0, VARPTR(rct(0)), 0)                  ' SPI_GETWORKAREA=48
  Result=rct(3)-rct(0)                                            ' Screen work area
END FUNCTION

'*****************************************
' "X" of MainForm
SUB MainClose(Action)
  IF ObjectIndex>ComponentCount THEN                              ' Changes?
    Action=False
    IF MessageBox("QUIT without saving changes?", _
    "Project updated...",&h124) = mrNo THEN EXIT SUB    ' Keep going
  END IF
  UnhookWindowsHookEx(hHook)                                      ' Remove our windows mouse hook
  Action=True                                                     ' Ok we are finished!
END SUB

'*****************************************
' Disable "X" in user generated form(s)
SUB NoClose(Action)
  Action=False
END SUB

'*****************************************
FUNCTION FindHelpFile() AS integer
  DEFSTR tstr, curPath

  Result=False
  curPath=Application.Path
  tstr=LEFT$(curPath,RINSTR(curPath,"\"))+"help\rapidq.chm"       ' FreeQ help folder?
  IF FileExists(tstr) THEN
    RQHelpFile=tstr
    Result=True
    EXIT FUNCTION
  END IF
  tstr=curPath+"\rapidq.chm"                                      ' Current folder?
  IF FileExists(tstr) THEN
    RQHelpFile=tstr
    Result=True
    EXIT FUNCTION
  END IF
  tstr=curPath+"\Help\rapidq.chm"                                  ' Mine c:\RapidQ\Help
  IF FileExists(tstr) THEN
    RQHelpFile=tstr
    Result=True
    EXIT FUNCTION
  END IF
END FUNCTION

'*****************************************
SUB HelpOnObject'!!!! <<< необновленные процедуры
  DEFSTR tstr, helpStr
  DEFLNG PID

  ' From the doco:
  '   ms-its:Helpfile.chm::/Topic.htm[>Window name]
  '   mk:@MSITStore:Helpfile.chm::/Topic.htm[>Window name]
  '
  tstr=AddedObjectList(CurrentObject)
  tstr=FIELD$(tstr,"|",2)+".html"                                 ' Object page in the help file
  '    helpStr="HH.exe mk:@MSITStore:"+RQHelpFile+"::/"+tstr
  helpStr="HH.exe ms-its:"+RQHelpFile+"::/"+tstr
  PID=SHELL(helpStr)
  WaitOnHelp(PID,-1)
END SUB

'*****************************************
SUB AboutClick'!!!! <<< необновленные процедуры
  DEFSTR tstr

  tstr="RapidFRM - Form Designer/Editor for RapidQ & FreeBasic"+CRLF
  tstr=tstr+"Copyright (c) 2009-2013 Don Homans"+CRLF
  tstr=tstr+"Contact: d_homans@yahoo.com.au"+CRLF+CRLF
  tstr=tstr+"Thanks to:"+CRLF
  tstr=tstr+"        William Yu"+CRLF
  tstr=tstr+"        RapidQ contributions from Jordi Ramos & JohnK"+CRLF
  tstr=tstr+"        FreeBasic guidance from the FreeBasic community"+CRLF+CRLF
  tstr=tstr+"You may freely copy/modify the source code of this program"+CRLF
  tstr=tstr+"for your own purposes, provided that you give me and this"+CRLF
  tstr=tstr+"original program reasonable recognition in your production."+CRLF+CRLF
  tstr=tstr+"This program is FREE.  Use at your own risk!"
  MessageBox(tstr,"RapidFRM "+VER,&h40)
END SUB

'*****************************************
' General help using the single butn at top of screen
SUB HelpBtnClick'!!!! <<< необновленные процедуры
  DesignTab.Tag=0
  DesignTab.TabIndex=4
  DesignTabChange
END SUB

'*****************************************
SUB FillHelp(idx AS integer)'!!!! <<< необновленные процедуры
  DEFINT i
  DEFSTR tstr, token

  HelpText.Clear                                                  ' Clear help screen
  token="#"+STR$(idx)                                             ' Which section of help
  HelpRef.Position=0
  FOR i=1 TO HelpRef.LineCount                                    ' Position within the mem stream
    tstr=HelpRef.ReadLine
    IF FIELD$(tstr," ",1)=token THEN EXIT FOR
  NEXT i
  tstr=tstr-token
  HelpText.AddStrings tstr
  INC i
  FOR i=i TO HelpRef.LineCount                                    ' Fill the edit box
    tstr=HelpRef.ReadLine
    IF LEFT$(tstr,1)="#" THEN EXIT FOR                          ' Next section .. so exit
    HelpText.AddStrings tstr
  NEXT i
END SUB

'*****************************************
SUB NonVisPopup(X,Y)
  mnuAlign.Enabled=False
  mnuCopy.Enabled=False
  mnuPaste.Enabled=False
  mnuDelete.Enabled=True
  designMenu.Popup(X,Y)
END SUB

'*****************************************
' Right click on an object in Forms()
SUB ObjPopUp(X, Y)
  mnuAlign.Enabled=True
  mnuCopy.Enabled=True
  IF designMenu.Tag>0 THEN                                        ' Something copied?
    mnuPaste.Enabled=True
    MouseSaveX=X: MouseSaveY=Y
  ELSE
    mnuPaste.Enabled=False
    MouseSaveX=0: MouseSaveY=0
  END IF
  mnuDelete.Enabled=True
  designMenu.Popup(X,Y)
END SUB

'*****************************************
' Right click on Forms() itself
SUB FormPopUp(X, Y)
  mnuAlign.Enabled=False
  mnuCopy.Enabled=False
  IF designMenu.Tag>0 THEN                                        ' Something copied?
    mnuPaste.Enabled=True
    MouseSaveX=X: MouseSaveY=Y
  ELSE
    mnuPaste.Enabled=False
    MouseSaveX=0: MouseSaveY=0
  END IF
  mnuDelete.Enabled=False
  designMenu.Popup(X,Y)
END SUB

'*****************************************
' Recursively tunnel down to find which FORM this (objIndx) object belongs to
FUNCTION GetParentForm(objIndx AS integer) AS integer'!!!! <<< необновленные процедуры
  DEFINT i, max=objIndx
  DEFSTR tstr, parntStr, objStr=""

  WHILE objStr<>"0"
    tstr=FIELD$(AddedObjectList(max),"~",1)
    parntStr=FIELD$(tstr,"|",6)                                 ' Parent handle string
    FOR i=0 TO max-1
      tstr=FIELD$(AddedObjectList(i),"|",3)                        ' Find the index of the parent
      IF tstr=parntStr THEN
        objStr=FIELD$(AddedObjectList(i),"|",1)                  ' Parent object type, looking for a form
        max=i                                               ' reset max
        EXIT FOR
      END IF
    NEXT i
  WEND
  Result=max
END FUNCTION

'*****************************************
' Select a component from combo dropdown list
SUB SelectComboChange'!!!! <<< необновленные процедуры
  DEFINT i, frmIdx
  DEFLNG hWnd
  DEFSTR tstr
  DIM rect AS QRECT

  IF SelectionCombo.ItemIndex=CurrentObject THEN EXIT SUB
  HideCarets
  CurrentObject=SelectionCombo.ItemIndex                          ' Set the current object

  tstr=FIELD$(AddedObjectList(CurrentObject),"~",1)
  IF VAL(FIELD$(tstr,"|",1))<NON_VISIBLE THEN
    IF FIELD$(tstr,"|",1)<>"0" THEN                             ' Not a form?
      frmIdx=GetParentForm(CurrentObject)                     ' Drill down - find the associated form
      tstr=FIELD$(AddedObjectList(frmIdx),"~",1)
    END IF
    hWnd=VAL(FIELD$(tstr,"|",3))                                ' Handle of current form
    FOR i=1 TO FrmIndex-1
      IF hWnd=Forms(i).Handle THEN
        IF i<>FormIndex THEN
          FormIndex=i                                   ' Set current form
          FOR i=1 TO 8
            Carets(i).Parent=Forms(FormIndex)         ' Set carets to current form
          NEXT i
        END IF
        EXIT FOR
      END IF
    NEXT i
    tstr=FIELD$(AddedObjectList(CurrentObject),"~",1)
    IF FIELD$(tstr,"|",1)<>"0" THEN
      hWnd=VAL(FIELD$(tstr,"|",3))                            ' Handle of current object
      GetWindowRect(hWnd,rect)
      ShowCarets(rect)                                        ' Show carets
    END IF
  END IF
  UpdatePropGrid(CurrentObject)                                   ' Update String grid data
END SUB

' Change between component properties and events
'*****************************************
SUB ObjInspectorTabChange
  'FieldEdit.Visible=False                                         ' Ensure hidden
  'FieldBox.Visible=False                                          ' ditto

  SELECT CASE ObjInspectorTab.TabIndex
  CASE 0
    PropertyGrid.Visible=True
    MethodGrid.Visible=False
    EventGrid.Visible=False
    'RQCompGlobalGrid.Visible=False

  CASE 1
    PropertyGrid.Visible=False
    MethodGrid.Visible=False
    EventGrid.Visible=True'False
    'RQCompGlobalGrid.Visible=False
  CASE 2
    PropertyGrid.Visible=False
    MethodGrid.Visible=False
    EventGrid.Visible=True
    'RQCompGlobalGrid.Visible=False
  CASE 3
    PropertyGrid.Visible=False
    MethodGrid.Visible=False
    EventGrid.Visible=False
    'RQCompGlobalGrid.Visible=True

  END SELECT

END SUB

'*****************************************
SUB DesignTabChange
  call  AddClrString ("4278:DesignTabChange="+str$(DesignTabChange), clred, LogEdit)
  DEFINT i

  ObjInspectorTab.TabIndex=0
  ObjInspectorTabChange

  FOR i=1 TO FrmIndex-1
    'Forms(i).Visible=False
  NEXT i

  FormsPanel.Visible=False
  CodeText.Visible=False
  MenuPanel.Visible=False
  FBCodeText.Visible=False
  HelpText.Visible=False
  RQObjPanel.Visible=False


  GridFileName$=projectDir$+"\"+trim$(field$(cmboxObj.text," ",1))+".dat"

  '!!! сохраняем таблицу OldObjectIndex компонента
  PropertyGrid.SaveToFile(GridFileName$,0,0,PropertyGrid.RowCount)
  call  AddClrString ("4457:SaveToFile GridFileName$="+(GridFileName$), clred, LogEdit)


  SELECT CASE DesignTab.TabIndex
  CASE 0                                                      ' Form designer
    DesignTab.Tag=1                                         ' Preset tag for relevant help info
    FormsPanel.Visible=True
    FOR i=1 TO FrmIndex-1
      Forms(i).Visible=True
    NEXT i
  CASE 1                                                      ' RapidQ coder
    DesignTab.Tag=2                                         ' Preset tag for help info
    CodeText.Visible=True
    tplSave.Enabled=False
    BuildFormCode
  CASE 2                                                      ' Menu code copy/paste
    DesignTab.Tag=3                                         ' Preset tag for help info
    MenuEditor
  CASE 3                                                      ' FreeBasic coder
    DesignTab.Tag=4                                         ' Preset tag for help info
    FBCodeText.Visible=True
    tplSave.Enabled=True
    BuildFBCode                                             ' FreeBasic coder
  CASE 4
    HelpText.Visible=True
    FillHelp(DesignTab.Tag)
  CASE 5
    RQObjPanel.Visible=True
  END SELECT


END SUB

'------------------------ Buttons & Toolbars ------------------------------------------------
'*****************************************
SUB LoadSingleButtons
  DEFINT i

  ButtonImages.ExtractRes(8,4,clNone)                             ' Resource(8)
  FOR i=0 TO 3
    xtraBtns(i).Parent=ToolBox
    xtraBtns(i).Left=480+(i*30)                                 ' Button width + spacing
    xtraBtns(i).Top=20
    xtraBtns(i).Width=28
    xtraBtns(i).Height=28
    xtraBtns(i).Cursor=crHandPoint
    xtraBtns(i).Spacing=0
    xtraBtns(i).Flat=True
    xtraBtns(i).ShowHint=True
    xtraBtns(i).BMP=ButtonImages.GetBMP(i)                      ' Assign the bmp
    SELECT CASE i
    CASE 0: xtraBtns(i).Hint="ADD A FORM": xtraBtns(i).OnClick=AddNewForm
    CASE 1: xtraBtns(i).Hint="ABOUT": xtraBtns(i).OnClick=AboutClick
    CASE 2: xtraBtns(i).Hint="GENERAL HELP": xtraBtns(i).OnClick=HelpBtnClick
    CASE 3: xtraBtns(i).Hint="EXIT": xtraBtns(i).OnClick=AskExit
    END SELECT
  NEXT i
END SUB

'*****************************************
SUB LoadToolbarHints'!!!! <<< необновленные процедуры
  DEFINT i, lines, cnt=0
  DEFSTR tstr

  ToolbarHint=""                                                  ' A global used in several places
  ComponentRef.Position=0
  lines=ComponentRef.LineCount
  tstr=ComponentRef.ReadLine                                      ' Junk <# 0 QFORM>
  'call  AddClrString ("1663:tstr="+(tstr), cldb, LogEdit)
  FOR i=2 TO lines
    tstr=ComponentRef.ReadLine
    'call  AddClrString ("1666:tstr="+(tstr), cldp, LogEdit)
    IF LEFT$(tstr,1)="#" THEN
      ToolbarHint=ToolbarHint+FIELD$(tstr," ",3)+"~"
      INC cnt
      IF cnt>MAX_TOOLBTNS THEN EXIT FOR
    END IF
  NEXT i
  tstr=""
  FOR i=1 TO cnt
    tstr=tstr+FIELD$(ToolBarHint,"~",i)+","
    SELECT CASE i
    CASE 15: ToolBar1.Hint=tstr: tstr=""                    ' Btns  1-15
    CASE 29: ToolBar2.Hint=tstr: tstr=""                    ' Btns 16-29
    CASE 40: ToolBar3.Hint=tstr: tstr=""                    ' Btns 30-40
    CASE 44: ToolBar4.Hint=tstr: tstr=""                    ' Btns 41-44
    CASE 55: ToolBar5.Hint=tstr: tstr=""                    ' Btns 45-55
    END SELECT
  NEXT i
END SUB

'*****************************************
SUB ButnCmd(idx)                                                    ' Clicked on toolbar button
  call  AddClrString ("2200:idx="+str$(idx), clred, LogEdit)
  ScanTimer.Enabled=False

  FieldEdit.Visible=False
  FieldBox.Visible=False
  OldRow=-1

  DesignTab.TabIndex=0: DesignTabChange                           ' Ensure design tab visible
  ObjInspectorTab.TabIndex=0: ObjInspectorTabChange

  HideCarets

  SELECT CASE ToolBarTab.TabIndex
  CASE 0: NewObjectID=ToolBar1.Tag+idx                        ' Btns  1-15
  CASE 1: NewObjectID=ToolBar2.Tag+idx                        ' Btns 16-29
  CASE 2: NewObjectID=ToolBar3.Tag+idx                        ' Btns 30-40
  CASE 3: NewObjectID=ToolBar4.Tag+idx                        ' Btns 41-44
  CASE 4: NewObjectID=ToolBar5.Tag+idx                        ' Btns 45-55
  END SELECT

  IF NewObjectID >= NON_VISIBLE THEN                              ' Add immediately to non-vis area
    SELECT CASE ToolBarTab.TabIndex
    CASE 0: NonVisBMP.BMP=ToolBar1.tbButtons(idx).BMP       '
    CASE 1: NonVisBMP.BMP=ToolBar2.tbButtons(idx).BMP       '
    CASE 2: NonVisBMP.BMP=ToolBar3.tbButtons(idx).BMP       ' Grab a copy of button image
    CASE 3: NonVisBMP.BMP=ToolBar4.tbButtons(idx).BMP       '
    CASE 4: NonVisBMP.BMP=ToolBar5.tbButtons(idx).BMP       '
    END SELECT
    AddNewObject(0)
  END IF
  ScanTimer.Enabled=True                                               ' Else wait for user to place on form
  'call  AddClrString ("2140:ScanTimer.Enabled="+str$(ScanTimer.Enabled), clred, LogEdit)
END SUB

'*****************************************
SUB ToolTabChange
  'Deselect
  ToolBar1.Visible=False: ToolBar2.Visible=False: ToolBar3.Visible=False
  ToolBar4.Visible=False: ToolBar5.Visible=False
  SELECT CASE ToolBarTab.TabIndex
  CASE 0: ToolBar1.Visible=True
  CASE 1: ToolBar2.Visible=True
  CASE 2: ToolBar3.Visible=True
  CASE 3: ToolBar4.Visible=True
  CASE 4: ToolBar5.Visible=True
  END SELECT
END SUB

'--------------------- Form(s) stuff -------------------------------------------------
'*****************************************
FUNCTION UpdateDefProperties(defString AS string, X AS integer, Y AS integer, _ '!!!! <<< необновленные процедуры
                             Width AS integer, Height AS integer, strText AS string) AS string
  DEFINT i, cnt
  DEFSTR token, resStr

  cnt=TALLY(defString,"~")
  resStr=" "
  FOR i=1 TO cnt
    token=FIELD$(defString,"~",i)
    SELECT CASE UCASE$(FIELD$(token,"|",1))
    CASE "LEFT": token=token-FIELD$(token,"|",4)+STR$(X)
    CASE "TOP": token=token-FIELD$(token,"|",4)+STR$(Y)
    CASE "WIDTH": token=token-FIELD$(token,"|",4)+STR$(Width)
    CASE "HEIGHT": token=token-FIELD$(token,"|",4)+STR$(Height)
    CASE "CAPTION": token=token-FIELD$(token,"|",4)+strText
    CASE "PARENT"
      IF INSTR(strText,"Form")=0 THEN                     ' If not a form object
        token=token-FIELD$(token,"|",4)
        IF FormIndex=0 THEN
          token=token+"MainForm"
        ELSE
          token=token+"Form"+STR$(FormIndex)
        END IF
      END IF
    END SELECT
    resStr=resStr+token+"~"
  NEXT i
  Result=LTRIM$(resStr)
END FUNCTION

'*****************************************
' Currently only a visual fudge for QSplitter AND only vertically (default)!!
SUB UpdateChildObjects(Sender AS QFORM) '!!!! <<< необновленные процедуры
  DEFINT i, j, splitLeft, splitWidth
  DEFLNG hWnd
  DEFSTR objStr, tstr, tok

  FOR i=CurrentObject+1 TO ObjectIndex
    objStr=AddedObjectList(i)
    IF objStr="" THEN EXIT FOR
    tstr=FIELD$(objStr,"~",1)
    tok=FIELD$(tstr,"|",6)                                      ' Parent handle
    IF (VAL(tok)=Sender.Handle) AND (FIELD$(tstr,"|",2)="QSPLITTER") THEN
      hWnd=VAL(FIELD$(tstr,"|",3))                            ' Object handle
      FOR j=2 TO TALLY(objStr,"~")
        tstr=UCASE$(FIELD$(objStr,"~",j))
        tok=TRIM$(FIELD$(tstr,"|",1))
        SELECT CASE tok
        CASE "LEFT": tok=TRIM$(FIELD$(tstr,"|",4)): splitLeft=VAL(tok)
        CASE "WIDTH": tok=TRIM$(FIELD$(tstr,"|",4)): splitWidth=VAL(tok)
        END SELECT
      NEXT j
      SetWindowPos(hWnd, 0, splitLeft, 0, splitWidth, Sender.ClientHeight, SW_FLAGS)
      EXIT FOR
    END IF
  NEXT i
END SUB


'!*****************************************
SUB ReSizeForm(Sender)
  'call  AddClrString ("2539:ReSizeForm="+str$(ReSizeForm), subclr, LogEdit)
  'call  AddClrString ("2540:Sender.Handle="+str$(Sender.Handle), subclr, LogEdit)

  DEFSTR tstr, saveStr
  DEFINT idx

  ''call  AddClrString ("2142:flParsed="+str$(flParsed), clp, LogEdit)
  if flParsed=1 then goto exitReSizeForm


  HideCarets

  '!!! чудо не срабатывает функция!!! не заходит внутрь FormIndex=WhichFormIsActive(Sender.Handle)                    ' Index in Forms()

  ''call  AddClrString ("2070:resize form FormIndex="+str$(FormIndex), clred, LogEdit)
  idx=HandleToIndex(Sender.Handle)                          ' Get index in AddedObjectList()
  ''call  AddClrString ("2072:idx="+str$(idx), clred, LogEdit)

  if gMouseBtns=0 then

    For rowi=1 to PropertyGrid.RowCount-1
      celli=trim$(lcase$(PropertyGrid.Cell(0, rowi))) ' имя свойства
      ''call  AddClrString ("2153:celli="+(celli), clm, LogEdit)
      if  trim$(celli)="width"  then
        PropertyGrid.Cell(1, rowi)=str$(Forms(FormIndex).width)
        ''call  AddClrString ("2156:Forms("+str$(FormIndex)+"width)="+str$(Forms(FormIndex).width), clm, LogEdit)
      end if
      if  trim$(celli)="height"  then
        PropertyGrid.Cell(1, rowi)=str$(Forms(FormIndex).height)
        ''call  AddClrString ("2160:Forms("+str$(FormIndex)+"height)="+str$(Forms(FormIndex).height), clm, LogEdit)
      end if
      if  trim$(celli)="top"  then
        PropertyGrid.Cell(1, rowi)=str$(Forms(FormIndex).top)
      end if
      if  trim$(celli)="left"  then
        PropertyGrid.Cell(1, rowi)=str$(Forms(FormIndex).left)
      end if


    next rowi
    ''call  AddClrString ("2178:rowi="+str$(rowi), clred, LogEdit)

    'сохранить таблицу сейчас. Или при переключении на другой компонент.

    exitReSizeForm:
    brem 0
    !!!!!!!!!!!
    erem
  end if
END SUB


'*****************************************
SUB ReSizeForm_OLD(Sender)
  'call  AddClrString ("2296:ReSizeForm="+str$(ReSizeForm), clg, LogEdit)
  DEFSTR tstr, saveStr
  DEFINT idx

  HideCarets
  FormIndex=WhichFormIsActive(Sender.Handle)                    ' Index in Forms()
  idx=HandleToIndex(Sender.Handle)                          ' Get index in AddedObjectList()
  call  AddClrString ("2314:idx="+str$(idx), clred, LogEdit)

  if gMouseBtns=0 then
    IF (idx >= 0) AND (idx <= MAX_OBJECTS) THEN
      CurrentObject=idx
      tstr=AddedObjectList(idx)
      saveStr=FIELD$(tstr,"~",1)+"~"
      tstr=tstr-saveStr
      tstr=UpdateDefProperties(tstr, Sender.Left, Sender.Top, _
                               Sender.Width, Sender.Height, Sender.Caption)
      AddedObjectList(idx)=saveStr+tstr                                ' Update global string
      UpdatePropGrid(idx)                                         ' Update String grid
      UpdateChildObjects(Sender)
    END IF
  end if
END SUB



'!*****************************************
SUB FormsOnMouseMove(X, Y, Shift, Sender)
  ''call  AddClrString ("2758:FormsOnMouseMove=", subclr, LogEdit)
  ''call  AddClrString ("2538:Y="+str$(Y), clred, LogEdit)
  ''call  AddClrString ("2538:X="+str$(X), clred, LogEdit)
  DEFINT i

  i=WhichFormIsActive(Sender.Handle)
  IF i<>FormIndex THEN
    FormIndex=i
    'call  AddClrString ("2764:FormsOnMouseMove FormIndex="+str$(FormIndex), cldb, LogEdit)
    HideCarets                                                  ' If visible
    FOR i=1 TO 8
      Carets(i).Parent=Sender                                 ' Set carets to this form
    NEXT i
  END IF
  StBarFrmDsg.Panel(1).Caption="  Active Form = "+STR$(FormIndex)
  StBarFrmDsg.Panel(2).Caption="  X="+STR$(X)+": Y="+STR$(Y)

END SUB



'*****************************************
SUB FormsOnMouseMove_OLD(X, Y, Shift, Sender)
  DEFINT i

  i=WhichFormIsActive(Sender.Handle)
  IF i<>FormIndex THEN
    FormIndex=i
    HideCarets                                                  ' If visible
    FOR i=1 TO 8
      Carets(i).Parent=Sender                                 ' Set carets to this form
    NEXT i
  END IF
  stat.Panel(1).Caption="  Active Form = "+STR$(FormIndex)
  stat.Panel(2).Caption="  X="+STR$(X)+": Y="+STR$(Y)

END SUB

'*****************************************
SUB PaintFormGrid(Sender)
  DEFINT px, py

  FOR py=0 TO Sender.Height STEP 10
    FOR px=0 TO Sender.Width STEP 10
      Sender.Pset(px, py, &h7f7f7f)
    NEXT px
  NEXT py
END SUB

'----------------------- Updating component fields -------------------------------------
'
'*****************************************
SUB MethodUpdate(newStrings AS string)'!!!! <<< необновленные процедуры
  DEFINT i, cnt
  DEFLNG hWnd
  DEFSTR tstr, token

  IF LEN(newStrings)=0 THEN newStrings=" "                        ' Don't allow to delete ALL tabs!
  tstr=AddedObjectList(CurrentObject)
  tstr=FIELD$(tstr,"~",1)
  hWnd=VAL(FIELD$(tstr,"|",7))
  SELECT CASE FIELD$(tstr,"|",2)
  CASE "QTABCONTROL"
    DelAllTabs(hWnd)
    i=0: cnt=TALLY(newStrings,",")+1
    DO
      token=FIELD$(newStrings,",",i+1)
      IF token<> "" THEN AddNewTab(hWnd,i,token)
      INC i
    LOOP UNTIL i=cnt
  END SELECT
END SUB


'!*****************************************
function GetPropString (prop as string) as string
  call  AddClrString ("4803:GetPropString="+prop, subclr, LogEdit)

  defint PropValue
  defint rowi, ci
  defstr celli
  defstr consti

  prop=trim$(lcase$(prop))
  ''call  AddClrString ("4005:prop="+(prop), clred, LogEdit)

  For rowi=1 to PropertyGrid.RowCount-1
    celli=trim$(lcase$(PropertyGrid.Cell(0, rowi)))
    if  trim$(celli)=prop  then
      call  AddClrString ("4010:GetPropString Prop Name="+(celli), clred, LogEdit)
      celli=trim$(lcase$(PropertyGrid.Cell(1, rowi)))
      call  AddClrString ("4817:Prop value="+(celli), clred, LogEdit)
      exit for
    end if
  next rowi

  GetPropString= celli
  call  AddClrString ("4824:GetPropString="+(celli), cllr, LogEdit)

end function



'*****************************************
' если оформить процедурой
function GetPropString_OLD (prop as string) as string

  defint PropValue
  defint rowi, ci
  defstr celli
  defstr consti


  For rowi=1 to PropertyGrid.RowCount-1
    celli=trim$(lcase$(PropertyGrid.Cell(0, rowi)))
    if  trim$(celli)=prop  then
      call  AddClrString ("2348:celli="+(celli), clred, LogEdit)
      celli=trim$(lcase$(PropertyGrid.Cell(1, rowi)))


      exit for
    end if
  next rowi

  GetPropString= celli
  'call  AddClrString ("2009:PropValue="+str$(PropValue), cllr, LogEdit)

end function



'!*****************************************
function GetPropValue (prop as string) as integer
  call  AddClrString ("--- 3710:GetPropValue prop="+(prop), subclr, LogEdit)

  defint PropValue=-999
  defint rowi, ci
  defstr celli
  defstr consti

  prop=lcase$(prop)
  'call  AddClrString ("3309:prop="+(prop), clred, LogEdit)
  'call  AddClrString ("3876:GetPropValue PropertyGrid.RowCount="+str$(PropertyGrid.RowCount), clo, LogEdit)

  For rowi=1 to PropertyGrid.RowCount-1
    celli=trim$(lcase$(PropertyGrid.Cell(0, rowi))) ' имя свойства
    'call  AddClrString ("2374:celli="+(celli), cldp, LogEdit)

    if  celli=lcase$(prop)  then 'если название свойства совпадает с заданным

      celli=trim$(lcase$(PropertyGrid.Cell(1, rowi)))
      'call  AddClrString ("4727:celli="+(celli), clred, LogEdit)

      if IsDigitsOnly(celli)=0 then
        'if val(celli)=0 then

        if PropertyGrid.Cell(2, rowi)<>"" then
          celli=trim$(lcase$(PropertyGrid.Cell(2, rowi)))
          'call  AddClrString ("4907:celli="+str$(celli), clred, LogEdit)
        else
          'celli="0"
        end if

      end if

      call DelComments(@celli)
      celli=trim$(celli)
      'call  AddClrString ("----------- 2375:celli="+(celli), clb, LogEdit)
      'call  AddClrString ("3972:Hex2Dec("+(celli)+")="+(Hex2Dec(celli)), clred, LogEdit)

      PropValue=val(celli)
      'call  AddClrString ("3962:PropValue="+str$(PropValue), clred, LogEdit)

      if instr(prop,"color")>0 then
        'call  AddClrString ("4904:prop="+(prop), clred, LogEdit)



        if instr(celli,"default")>0 then
          'call  AddClrString ("3890:color celli="+(celli), clred, LogEdit)
          PropValue=clWhite
          'call  AddClrString ("4835:clWhite="+str$(clWhite), clred, LogEdit)
        else

          'call  AddClrString ("4912:celli="+(celli), cldb, LogEdit)
          'call  AddClrString ("4913:Hex2Dec("+(celli)+")="+(Hex2Dec(celli)), clred, LogEdit)
          zzzz$=Hex2Dec(celli)
          'call  AddClrString ("4914:zzzz$="+(zzzz$), clred, LogEdit)
          'PropValue=val(Hex2Dec(celli))
          dddd&=val(zzzz$)
          'call  AddClrString ("4917:dddd&="+str$(dddd&), clred, LogEdit)
          PropValue=dddd& 'val(zzzz$)

          'call  AddClrString ("3776:PropValue color="+str$(PropValue), cldp, LogEdit)

        end if
      elseif prop="selstart"  then

      elseif prop="hint"  then
        consti=trim$(lcase$(PropertyGrid.Cell(1, rowi)))
        PropValueS=consti
        exit function
      elseif prop="center"  then
        PropValue="1"
        'call  AddClrString ("4895:PropValue="+str$(PropValue), clb, LogEdit)
      else
        consti=trim$(lcase$(PropertyGrid.Cell(2, rowi)))
        'PropValue=val(consti)
      end if


      exit for
    end if
  next rowi

  GetPropValue= PropValue
  ''call  AddClrString ("2009:PropValue="+str$(PropValue), cllr, LogEdit)

end function



'*****************************************
' если оформить процедурой
function GetPropValue_OLD (prop as string) as integer
  'call  AddClrString ("2364:prop="+(prop), clg, LogEdit)

  defint PropValue
  defint rowi, ci
  defstr celli
  defstr consti

  prop=lcase$(prop)
  For rowi=1 to PropertyGrid.RowCount-1
    celli=trim$(lcase$(PropertyGrid.Cell(0, rowi)))
    'call  AddClrString ("2374:celli="+(celli), clred, LogEdit)
    if  trim$(celli)=lcase$(prop)  then
      'call  AddClrString ("2440:lcase$((prop)="+(lcase$(prop)), clred, LogEdit)
      'call  AddClrString ("2375:celli="+(celli), clb, LogEdit)
      celli=trim$(lcase$(PropertyGrid.Cell(1, rowi)))

      if instr(prop,"color")>0 then

        if instr(celli,"default")>0 then
          PropValue=clSilver
        else
          PropValue=val(Hex2Dec(celli))
        end if
      elseif prop="selstart"  then

      elseif prop="hint"  then
        consti=trim$(lcase$(PropertyGrid.Cell(1, rowi)))
        PropValueS=consti
        exit function
      else
        consti=trim$(lcase$(PropertyGrid.Cell(2, rowi)))
        PropValue=val(consti)
      end if


      exit for
    end if
  next rowi

  GetPropValue= PropValue
  'call  AddClrString ("2009:PropValue="+str$(PropValue), cllr, LogEdit)

end function


'!*****************************************
SUB ReDrawComponentByField
  call  AddClrString ("3815:ReDrawComponentbyField================", subclr, LogEdit)
  DEFSTR propString, token, tstr, cap
  DEFINT i, X, Y, Height, Width,  reposn,ObjTIdx, fld
  DEFLNG hWnd
  DIM rect AS QRECT

  defint rowi, ci
  defstr celli
  defstr const_i

  call  AddClrString ("3332:ReDrawComponentbyField ObjectType("+str$(ObjectIndex)+")="+(ObjectType(ObjectIndex)), clm, LogEdit)

  ObjTIdx=ObjTypeIndex(ObjectIndex) '!!! может путаться в ObjectIndex
  call  AddClrString ("3827:ObjTypeIndex("+str$(ObjectIndex)+")="+str$(ObjTypeIndex(ObjectIndex)), clred, LogEdit)
  'call  AddClrString ("3335:ObjTIdx="+str$(ObjTIdx), clm, LogEdit)

  objname$=ObjectName(ObjectIndex)
  call  AddClrString ("4980: >>>>>>>>>>. objname$="+(objname$), cldg, LogEdit)

  if ObjTIdx>100 then
    Showmessage("3383: Too many object types "+str$(ObjTIdx))
    exit sub
  end if
  call  AddClrString ("3834:ObjectType("+str$(ObjectIndex)+")="+(ObjectType(ObjectIndex)), clm, LogEdit)
  call  AddClrString ("4805:flParsed="+str$(flParsed), clred, LogEdit)

  if flParsed=0 then ' свойства!!!  компонента, если он устанавливается с палитры

    if ucase$(ObjectType(ObjectIndex))<>"QFORM" and ucase$(ObjectType(ObjectIndex))<>"QSCROLLBAR" then
      X =GetPropValue ("Left")
      Y=GetPropValue ("Top")
      Width =GetPropValue ("Width")
      'call  AddClrString ("3876:Width="+str$(Width), 0, LogEdit)
      if Width <=0 then Width =70
      Height=GetPropValue ("Height")
      'call  AddClrString ("3879:Height="+str$(Height), 0, LogEdit)
      if Height <=0 then Height =50

      HideCarets                                                  ' If visible
      SetWindowPos(hWnd, 0, X, Y, Width, Height, SW_FLAGS)
      GetWindowRect(hWnd,rect)
      ShowCarets(rect)

    END IF
  else
    brem 0
    ==================
    '! переписываем в таблицу свойств из PropList.dat
    ' PropertyFieldUpdate("Left",STR$(Left))                        !!!!

    GridListFileName$=projectDir$+"\"+objname$+"PropList.dat"
    call  AddClrString ("5014: GridListFileName$="+(GridListFileName$), cldr, LogEdit)
    PropertyListGrid.LoadFromFile(GridListFileName$,0,0,100)
    'PropertyListGrid

    for i=1 to PropertyListGrid.RowCount-1
      plg1$=PropertyListGrid.Cell(0,i)
      call  AddClrString ("5018:plg1$="+(plg1$), clred, LogEdit)
      plg2$=PropertyListGrid.Cell(1,i)
      call  AddClrString ("5020:plg2$="+(plg2$), clred, LogEdit)
      PropertyFieldUpdate(plg1$,plg2$)          '              !!!!
      if plg1$="center" then center=1

    next i
    ======================
    erem

  END IF

  ''call  AddClrString ("3506:Q_PANEL="+str$(Q_PANEL), clp, LogEdit)
  'call  AddClrString ("3404:ucase$(str$(ObjectType(ObjectIndex)="+(ucase$(ObjectType(ObjectIndex))), clp, LogEdit)

  'call  AddClrString ("4840:ucase$("+ObjectType(ObjectIndex)+")="+(ucase$(ObjectType(ObjectIndex))), clred, LogEdit)

  ' Visible components
  SELECT CASE  ucase$(ObjectType(ObjectIndex)) 'objType

  CASE "QFORM"          '0

    fld=GetPropValue ("Left"):if fld>-999 then Forms(ObjTIdx).Left=fld
    call  AddClrString ("4844:fld="+str$(fld), clred, LogEdit)
    fld=GetPropValue ("Top"):if fld>-999 then Forms(ObjTIdx).Top=fld
    fld=GetPropValue ("Width"):if fld>-999 then Forms(ObjTIdx).Width=(fld)
    fld=GetPropValue ("Height"):if fld>-999 then Forms(ObjTIdx).Height=(fld)
    fld=GetPropValue ("AutoScroll"):if fld>-999 then Forms(ObjTIdx).AutoScroll=fld
    Forms(ObjTIdx).caption=GetPropString ("caption")-qt' BevelOuter
    fld=GetPropValue ("BorderStyle"):if (fld>-999 ) then Forms(ObjTIdx).BorderStyle=fld 'bsToolWindow 'fld
    'call  AddClrString ("4876:BorderStyle fld="+str$(fld), clred, LogEdit)

    ObjectHandle(ObjectIndex)=Forms(ObjTIdx).handle '! после изменения свойства меняется handle ! ! !

    call  AddClrString ("4879:Forms("+str$(ObjTIdx)+"handle)="+str$(Forms(ObjTIdx).handle), clb, LogEdit)
    PropertyFieldUpdate("handle", str$(Forms(ObjTIdx).handle))

    'fld=GetPropValue ("center"):
    if center=1 then
      Forms(ObjTIdx).center '=fld
      center=0
    end if
    'call  AddClrString ("5047:center fld="+str$(fld), clred, LogEdit)



    fld=GetPropValue ("color"):if fld>-999 then Forms(ObjTIdx).color=fld
    call  AddClrString ("4984:!!!!!!!!! Form color fld="+str$(fld), cldb, LogEdit)
    fld=GetPropValue ("Cursor"):if fld>-999 then Forms(ObjTIdx).Cursor=fld
    '!!! fld=GetPropValue ("Font"):if fld>-999 then Forms(ObjTIdx).Font=fld
    fld$=GetPropString ("Hint")-qt:if fld$<>"" then Forms(ObjTIdx).Hint=fld$
    fld$=GetPropString ("icon")-qt:if fld$<>"" then Forms(ObjTIdx).icon=fld$
    'Forms(ObjTIdx).icon=GetPropString ("icon")-qt

    fld=GetPropValue ("ShowHint"):if fld>-999 then Forms(ObjTIdx).ShowHint=fld
    'call  AddClrString ("4860:fld="+str$(fld), clred, LogEdit)

    '!!! Forms(ObjTIdx).WindowState=GetPropValue ("WindowState")
    'fld=GetPropValue ("BorderStyle"):if fld>-999 then Forms(ObjTIdx).BorderStyle=fld
    'fld=GetPropValue ("FormStyle"):if fld>-999 then Forms(ObjTIdx).FormStyle=fld
    'fld=GetPropValue ("IcoHandle"):if fld>-999 then Forms(ObjTIdx).IcoHandle=fld
    'fld=GetPropValue ("KeyPreview"):if fld>-999 then Forms(ObjTIdx).KeyPreview=fld

    Forms(ObjTIdx).repaint

  CASE "QEDIT"          '1

    'call  AddClrString ("2450:Q_EDIT="+str$(Q_EDIT), clm, LogEdit)

    hWnd=BoxEdit(ObjTIdx).Handle
    'call  AddClrString ("3247:hWnd="+str$(hWnd), clp, LogEdit)

    'Align
    fld=GetPropValue ("Align"):if fld>-999 then BoxEdit(ObjTIdx).Align=fld
    fld=GetPropValue ("BorderStyle"):if (fld>-999 and fld<3) then BoxEdit(ObjTIdx).BorderStyle=fld
    ObjectHandle(ObjectIndex)=BoxEdit(ObjTIdx).handle
    'call  AddClrString ("5013:ObjectHandle("+str$(ObjTIdx)+")="+str$(ObjectHandle(ObjTIdx)), clred, LogEdit)

    fld=GetPropValue ("Color"):if fld>-999 then BoxEdit(ObjTIdx).Color=fld
    '!!! fld=GetPropValue ("Font"):if fld>-999 then BoxEdit(ObjTIdx).Font=fld
    fld=GetPropValue ("Height"):if fld>-999 then BoxEdit(ObjTIdx).Height=fld
    fld$=GetPropString ("Hint")-qt:if fld$<>"" then BoxEdit(ObjTIdx).Hint=fld$
    fld=GetPropValue ("Left"):if fld>-999 then BoxEdit(ObjTIdx).Left=fld
    fld=GetPropValue ("ShowHint"):if fld>-999 then BoxEdit(ObjTIdx).ShowHint=fld
    'fld=GetPropValue ("Text"):if fld>-999 then BoxEdit(ObjTIdx).Caption=fld
    fld$=GetPropString ("Text")-qt:if fld$<>"" then BoxEdit(ObjTIdx).Caption=fld$
    fld=GetPropValue ("Top"):if fld>-999 then BoxEdit(ObjTIdx).Top=fld
    fld=GetPropValue ("Width"):if fld>-999 then BoxEdit(ObjTIdx).Width=fld
    fld=GetPropValue ("Cursor"):if fld>-999 then BoxEdit(ObjTIdx).Cursor=fld

    BoxEdit(ObjTIdx).BevelOuter=0
    'redraw
    BoxEdit(ObjTIdx).visible=false
    BoxEdit(ObjTIdx).visible=true'
    ObjectHandle(ObjectIndex)=BoxEdit(ObjTIdx).handle
    'call  AddClrString ("5031:ObjectHandle("+str$(ObjectIndex)+")="+str$(ObjectHandle(ObjectIndex)), clred, LogEdit)


  CASE "QRICHEDIT"
    '2

    'BoxRICH(ObjTIdx).BevelOuter=0
    fld=GetPropValue ("Align"):if fld>-999 then BoxRICH(ObjTIdx).Align=fld

    fld=GetPropValue ("Alignment"):if fld>-999 then BoxRICH(ObjTIdx).Alignment=fld

    ''call  AddClrString ("3892:BoxRICH("+str$(ObjTIdx)+"handle)="+str$(BoxRICH(ObjTIdx).handle), clb, LogEdit)
    ''call  AddClrString ("3896:ObjectHandle("+str$(ObjectIndex)+")="+str$(ObjectHandle(ObjectIndex)), clred, LogEdit)
    ''call  AddClrString ("3893:BoxRICH("+str$(ObjTIdx)+"BorderStyle)="+str$(BoxRICH(ObjTIdx).BorderStyle), cldg, LogEdit)
    fld=GetPropValue ("BorderStyle"):if (fld>-999 and fld<3)  then BoxRICH(ObjTIdx).BorderStyle=fld

    ObjectHandle(ObjectIndex)=BoxRICH(ObjTIdx).handle
    ''call  AddClrString ("3892:BoxRICH("+str$(ObjTIdx)+"handle)="+str$(BoxRICH(ObjTIdx).handle), clb, LogEdit)
    ''call  AddClrString ("3896:ObjectHandle("+str$(ObjectIndex)+")="+str$(ObjectHandle(ObjectIndex)), clred, LogEdit)
    ''call  AddClrString ("3893:BoxRICH("+str$(ObjTIdx)+"BorderStyle)="+str$(BoxRICH(ObjTIdx).BorderStyle), cldg, LogEdit)


    fld=GetPropValue ("Color"):if fld>-999 then BoxRICH(ObjTIdx).Color=fld
    'fld=GetPropValue ("Font"):if fld>-999 then BoxRICH(ObjTIdx).Font=fld
    fld=GetPropValue ("Height"):if fld>-999 then BoxRICH(ObjTIdx).Height=fld
    fld$=GetPropString ("Hint")-qt:if fld$<>"" then BoxRICH(ObjTIdx).Hint=fld$
    fld=GetPropValue ("Left"):if fld>-999 then BoxRICH(ObjTIdx).Left=fld
    fld=GetPropValue ("ShowHint"):if fld>-999 then BoxRICH(ObjTIdx).ShowHint=fld
    fld$=GetPropString ("Text")-qt:if fld$<>"" then BoxRICH(ObjTIdx).caption=fld$
    fld=GetPropValue ("Top"):if fld>-999 then BoxRICH(ObjTIdx).Top=fld
    fld=GetPropValue ("Width"):if fld>-999 then BoxRICH(ObjTIdx).Width=fld
    fld=GetPropValue ("Cursor"):if fld>-999 then BoxRICH(ObjTIdx).Cursor=fld

    'redraw
    BoxRICH(ObjTIdx).visible=false
    BoxRICH(ObjTIdx).visible=true'
    ObjectHandle(ObjectIndex)=BoxRICH(ObjTIdx).handle


  CASE "QLABEL"         '3 BoxLabel(1)
    'call  AddClrString ("4946:BoxLabel("+str$(LabelIndex)+"Handle)="+str$(BoxLabel(LabelIndex).Handle), clp, LogEdit)

    fld=GetPropValue ("Height"):if fld>-999 then BoxLabel(ObjTIdx).Height=fld else BoxLabel(ObjTIdx).Height=13
    fld=GetPropValue ("Left"):if fld>-999 then BoxLabel(ObjTIdx).Left=fld
    fld=GetPropValue ("Top"):if fld>-999 then BoxLabel(ObjTIdx).Top=fld
    fld=GetPropValue ("Width"):if fld>-999 then BoxLabel(ObjTIdx).Width=fld else BoxLabel(ObjTIdx).Width=32

    fld=GetPropValue ("Align"):if fld>-999 then BoxLabel(ObjTIdx).Align=fld
    fld=GetPropValue ("Color"):if fld>-999 then BoxLabel(ObjTIdx).Color=fld
    'fld=GetPropValue ("Font"):if fld>-999 then BoxLabel(ObjTIdx).Font=fld
    fld=GetPropValue ("ShowHint"):if fld>-999 then BoxLabel(ObjTIdx).ShowHint=fld
    fld=GetPropValue ("Cursor"):if fld>-999 then BoxLabel(ObjTIdx).Cursor=fld

    fld=GetPropValue ("Alignment"):if fld>-999 then BoxLabel(ObjTIdx).Alignment=fld
    'fld=GetPropValue ("Angle"):if fld>-999 then BoxLabel(ObjTIdx).Angle=fld
    'fld=GetPropValue ("Autosize"):if fld>-999 then BoxLabel(ObjTIdx).Autosize=fld
    'fld=GetPropValue ("LabelStyle"):if fld>-999 then BoxLabel(ObjTIdx).LabelStyle=fld
    'fld=GetPropValue ("Layout"):if fld>-999 then BoxLabel(ObjTIdx).Layout=fld
    'fld=GetPropValue ("LowerColor"):if fld>-999 then BoxLabel(ObjTIdx).LowerColor=fld
    'fld=GetPropValue ("Transparent"):if fld>-999 then BoxLabel(ObjTIdx).Transparent=fld
    'fld=GetPropValue ("UpperColor"):if fld>-999 then BoxLabel(ObjTIdx).UpperColor=fld
    'fld=GetPropValue ("Wordwrap"):if fld>-999 then BoxLabel(ObjTIdx).Wordwrap=fld
    BoxLabel(ObjTIdx).Caption=GetPropString ("Caption")-qt
    BoxLabel(ObjTIdx).Hint=GetPropString ("Hint")-qt
    BoxLabel(ObjTIdx).BorderStyle=bpNone
    BoxLabel(ObjTIdx).BevelWidth=0
    ObjectHandle(ObjectIndex)=BoxLabel(ObjTIdx).handle

    'redraw
    BoxLabel(ObjTIdx).visible=false
    BoxLabel(ObjTIdx).visible=true'
    'call  AddClrString ("4946:BoxLabel("+str$(LabelIndex)+"Handle)="+str$(BoxLabel(LabelIndex).Handle), clp, LogEdit)


  CASE "QBUTTON"        '4
    'call  AddClrString ("========= 3614:QBUTTON="+str$(QBUTTON), clred, LogEdit)

    fld=GetPropValue ("Align"):if fld>-999 then boxBut(ObjTIdx).Align=fld
    'fld=GetPropValue ("BorderStyle"):if fld>-999 then boxBut(ObjTIdx).BorderStyle=fld
    'fld=GetPropValue ("Color"):if fld>-999 then boxBut(ObjTIdx).Color=fld
    'fld=GetPropValue ("Font"):if fld>-999 then boxBut(ObjTIdx).Font=fld
    fld=GetPropValue ("Height"):if fld>-999 then boxBut(ObjTIdx).Height=fld else boxBut(ObjTIdx).Height=25
    fld=GetPropValue ("Left"):if fld>-999 then boxBut(ObjTIdx).Left=fld
    fld=GetPropValue ("ShowHint"):if fld>-999 then boxBut(ObjTIdx).ShowHint=fld
    boxBut(ObjTIdx).Caption=GetPropString ("Caption")-qt
    boxBut(ObjTIdx).Hint=GetPropString ("Hint")-qt
    fld=GetPropValue ("Top"):if fld>-999 then boxBut(ObjTIdx).Top=fld
    fld=GetPropValue ("Width"):if fld>-999 then boxBut(ObjTIdx).Width=fld else boxBut(ObjTIdx).Width=75
    fld=GetPropValue ("Cursor"):if fld>-999 then boxBut(ObjTIdx).Cursor=fld
    ObjectHandle(ObjectIndex)=boxBut(ObjTIdx).handle

    'redraw
    boxBut(ObjTIdx).visible=false
    boxBut(ObjTIdx).visible=true'

  CASE "QCOOLBTN"       '5
    'DIM BoxCool(1) AS QPANEL

    'fld$=GetPropString ("BMP")-qt: if fileexists(fld$)>0 then BoxCool(ObjTIdx).BMP=fld$
    fld=GetPropValue ("Align"):if fld>-999 then BoxCool(ObjTIdx).Align=fld
    'fld=GetPropValue ("BorderStyle"):if fld>-999 then BoxCool(ObjTIdx).BorderStyle=fld
    fld=GetPropValue ("Color"):if fld>-999 then BoxCool(ObjTIdx).Color=fld
    'fld=GetPropValue ("Font"):if fld>-999 then boxBut(ObjTIdx).Font=fld
    fld=GetPropValue ("Height"):if fld>-999 then BoxCool(ObjTIdx).Height=fld else BoxCool(ObjTIdx).Height=25
    BoxCool(ObjTIdx).Hint=GetPropString ("Hint")-qt
    fld=GetPropValue ("Left"):if fld>-999 then BoxCool(ObjTIdx).Left=fld
    fld=GetPropValue ("ShowHint"):if fld>-999 then BoxCool(ObjTIdx).ShowHint=fld
    BoxCool(ObjTIdx).Caption=GetPropString ("Caption")-qt
    fld=GetPropValue ("Top"):if fld>-999 then BoxCool(ObjTIdx).Top=fld
    fld=GetPropValue ("Width"):if fld>-999 then BoxCool(ObjTIdx).Width=fld else BoxCool(ObjTIdx).Width=25
    fld=GetPropValue ("Cursor"):if fld>-999 then BoxCool(ObjTIdx).Cursor=fld

    ObjectHandle(ObjectIndex)=BoxCool(ObjTIdx).handle

    'BoxCool(ObjTIdx).BevelOuter=2
    'redraw
    BoxCool(ObjTIdx).visible=false
    BoxCool(ObjTIdx).visible=true'

  CASE "QOVALBTN"       '6!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    'REDIM panelOval(QOVALIndex+1) AS QPANEL
    'reDIM Ovalb(QOVALIndex+1) AS QOVALBTN
    Ovalb(QOVALIndex).Parent=panelOval(QOVALIndex)
    Ovalb(QOVALIndex).Align=alClient
    Ovalb(QOVALIndex).Enabled=False                                        ' Passes clicks thru to panel
    Ovalb(QOVALIndex).Tag=QOVALIndex
    Ovalb(QOVALIndex).Color=cla
    Ovalb(QOVALIndex).Caption=token


    fld=GetPropValue ("Align"):if fld>-999 then panelOval(ObjTIdx).Align=fld
    panelOval(ObjTIdx).BorderStyle=0

    fld=GetPropValue ("Color"):if fld>-999 then Ovalb(ObjTIdx).Color=fld
    'fld=GetPropValue ("Font"):if fld>-999 then boxBut(ObjTIdx).Font=fld
    fld=GetPropValue ("Height"):if fld>-999 then panelOval(ObjTIdx).Height=fld
    Ovalb(ObjTIdx).Hint=GetPropString ("Hint")-qt
    Ovalb(ObjTIdx).Caption=GetPropString ("Caption")-qt
    panelOval(ObjTIdx).Hint=GetPropString ("Hint")-qt
    fld=GetPropValue ("Left"):if fld>-999 then panelOval(ObjTIdx).Left=fld
    fld=GetPropValue ("ShowHint"):if fld>-999 then panelOval(ObjTIdx).ShowHint=fld
    fld=GetPropValue ("Top"):if fld>-999 then panelOval(ObjTIdx).Top=fld
    fld=GetPropValue ("Width"):if fld>-999 then panelOval(ObjTIdx).Width=fld
    fld=GetPropValue ("Cursor"):if fld>-999 then panelOval(ObjTIdx).Cursor=fld

    fld$=GetPropString ("BMP")-qt: if fileexists(fld$)>0 then Ovalb(ObjTIdx).BMP=fld$
    'ColorHighLight
    'ColorShadow
    'Cursor
    'Down
    'Flat
    'GroupIndex
    'Layout
    'Spacing
    'Transparent
    'TransParentColor

    panelOval(ObjTIdx).BevelOuter=0
    'redraw
    ObjectHandle(ObjectIndex)=panelOval(ObjTIdx).handle
    Ovalb(ObjTIdx).Parent=panelOval(ObjTIdx)

    panelOval(ObjTIdx).visible=false
    panelOval(ObjTIdx).visible=true'

  CASE "QCHECKBOX"      '7
    'Check(CheckIndex) DIM Check(32) AS QCHECKBOX

    fld=GetPropValue ("Align"):if fld>-999 then Check(ObjTIdx).Align=fld
    'fld=GetPropValue ("Font"):if fld>-999 then boxBut(ObjTIdx).Font=fld
    fld=GetPropValue ("Height"):if fld>-999 then Check(ObjTIdx).Height=fld
    Check(ObjTIdx).Hint=GetPropString ("Hint")-qt
    fld=GetPropValue ("Left"):if fld>-999 then Check(ObjTIdx).Left=fld
    fld=GetPropValue ("ShowHint"):if fld>-999 then Check(ObjTIdx).ShowHint=fld
    Check(ObjTIdx).Caption=GetPropString ("Caption")-qt
    fld=GetPropValue ("Top"):if fld>-999 then Check(ObjTIdx).Top=fld
    fld=GetPropValue ("Width"):if fld>-999 then Check(ObjTIdx).Width=fld

    'redraw
    Check(ObjTIdx).visible=false
    Check(ObjTIdx).visible=true'


  CASE "QRADIOBUTTON"   '8
    'DIM Radio(32) AS QRADIOBUTTON

    fld=GetPropValue ("Align"):if fld>-999 then Radio(ObjTIdx).Align=fld
    'fld=GetPropValue ("Font"):if fld>-999 then Radio(ObjTIdx).Font=fld
    fld=GetPropValue ("Height"):if fld>-999 then Radio(ObjTIdx).Height=fld
    Radio(ObjTIdx).Hint=GetPropString ("Hint")-qt' BevelOuter
    Radio(ObjTIdx).caption=GetPropString ("caption")-qt' BevelOuter
    'call  AddClrString ("3729:Radio("+str$(ObjTIdx)+"caption)="+(Radio(ObjTIdx).caption), cldg, LogEdit)
    fld=GetPropValue ("Left"):if fld>-999 then Radio(ObjTIdx).Left=fld
    fld=GetPropValue ("ShowHint"):if fld>-999 then Radio(ObjTIdx).ShowHint=fld
    fld=GetPropValue ("Top"):if fld>-999 then Radio(ObjTIdx).Top=fld
    fld=GetPropValue ("Width"):if fld>-999 then Radio(ObjTIdx).Width=fld
    'redraw
    Radio(ObjTIdx).visible=false
    Radio(ObjTIdx).visible=true'


  CASE "QPANEL"         '9
    call  AddClrString ("4106:QPANEL="+str$(Q_PANEL), clp, LogEdit)
    call  AddClrString ("4150: >>>>>> before dPan("+str$(ObjTIdx)+").handle)="+str$(dPan(ObjTIdx).handle), clb, LogEdit)

    'fld=GetPropValue ("BorderStyle"):if fld>-999 then dPan(ObjTIdx).BorderStyle=fld
    fld=GetPropValue ("Color"):if fld>-999 then dPan(ObjTIdx).Color=fld
    call  AddClrString ("4111:dPan("+str$(ObjTIdx)+".Color)="+str$(dPan(ObjTIdx).Color), 888, LogEdit)
    'fld=GetPropValue ("Font"):if fld>-999 then boxBut(ObjTIdx).Font=fld
    fld=GetPropValue ("Height"):if fld>-999 then dPan(ObjTIdx).Height=fld
    call  AddClrString ("4114:dPan("+str$(ObjTIdx)+".Height)="+str$(dPan(ObjTIdx).Height), clred, LogEdit)
    dPan(ObjTIdx).Hint=GetPropString ("Hint")-qt'

    dPan(ObjTIdx).caption=GetPropString ("caption")-qt'

    fld=GetPropValue ("Left"):if fld>-999 then dPan(ObjTIdx).Left=fld
    fld=GetPropValue ("Top"):if fld>-999 then dPan(ObjTIdx).Top=fld
    fld=GetPropValue ("Width"):if fld>-999 then dPan(ObjTIdx).Width=fld
    call  AddClrString ("4140:Width="+str$(fld), clred, LogEdit)

    fld=GetPropValue ("ShowHint"):if fld>-999 then dPan(ObjTIdx).ShowHint=fld
    fld=GetPropValue ("alignment"):if fld>-999 then dPan(ObjTIdx).alignment=fld
    fld=GetPropValue ("bevelinner"):if fld>-999 then dPan(ObjTIdx).bevelinner=fld
    fld=GetPropValue ("bevelinner"):if fld>-999 then dPan(ObjTIdx).bevelinner=fld
    fld=GetPropValue ("bevelouter"):if fld>-999 then dPan(ObjTIdx).bevelouter=fld
    fld=GetPropValue ("bevelwidth"):if fld>-999 then dPan(ObjTIdx).bevelwidth=fld

    fld=GetPropValue ("BorderStyle"):if (fld>-999 and fld<3) then dPan(ObjTIdx).BorderStyle=fld

    doevents

    fld=GetPropValue ("Align"):if fld>-999 then dPan(ObjTIdx).Align=fld
    'call  AddClrString ("4108:dPan("+str$(ObjTIdx)+".Align)="+str$(dPan(ObjTIdx).Align), 888, LogEdit)

    ObjectHandle(ObjectIndex)=dPan(ObjTIdx).handle
    'call  AddClrString ("4150:>>>>>>>>> after dPan("+str$(ObjTIdx)+").handle)="+str$(dPan(ObjTIdx).handle), cldb, LogEdit)


    'call  AddClrString ("4181:dPan("+str$(ObjTIdx)+"Left)="+str$(dPan(ObjTIdx).Left), &HE2024D, LogEdit)
    'call  AddClrString ("4182:dPan("+str$(ObjTIdx)+"Top)="+str$(dPan(ObjTIdx).Top), &HE2024D, LogEdit)
    'call  AddClrString ("4181:dPan("+str$(ObjTIdx)+").Width)="+str$(dPan(ObjTIdx).Width), &HE2024D, LogEdit)
    'call  AddClrString ("4182:dPan("+str$(ObjTIdx)+").Height)="+str$(dPan(ObjTIdx).Height), &HE2024D, LogEdit)

    'sleep 1

  CASE "QTABCONTROL"    '10
    ' TabCtrl(TabContIndex+1) AS QTABCONTROL

    'fld=GetPropValue ("bevelinner"):if fld>-999 then dPan(ObjTIdx).bevelinner=fld
    fld=GetPropValue ("Height"):if fld>-999 then BoxTab(ObjTIdx).Height=fld
    fld=GetPropValue ("Left"):if fld>-999 then BoxTab(ObjTIdx).Left=fld
    fld=GetPropValue ("Top"):if fld>-999 then BoxTab(ObjTIdx).Top=fld
    fld=GetPropValue ("Width"):if fld>-999 then BoxTab(ObjTIdx).Width=fld

    fld=GetPropValue ("color"):if fld>-999 then TabCtrl(ObjTIdx).color=fld
    fld=GetPropValue ("align"):if fld>-999 then BoxTab(ObjTIdx).align=fld

    ObjectHandle(ObjectIndex)=BoxTab(ObjTIdx).handle
    TabCtrl(ObjTIdx).parent=BoxTab(ObjTIdx)
    call  AddClrString ("5278:BoxTab("+str$(ObjTIdx)+"handle)="+str$(BoxTab(ObjTIdx).handle), clred, LogEdit)

    fld=GetPropValue ("cursor"):if fld>-999 then TabCtrl(ObjTIdx).cursor=fld
    fld=GetPropValue ("showhint"):if fld>-999 then TabCtrl(ObjTIdx).showhint=fld
    TabCtrl(ObjTIdx).hint=GetPropString("hint")

    'TabCtrl(ObjTIdx).Font=StrFont(ObjectIndex)
    fld=GetPropValue ("buttonStyle"):if fld>-999 then TabCtrl(ObjTIdx).ButtonStyle=fld
    fld=GetPropValue ("FlatButtons"):if fld>-999 then TabCtrl(ObjTIdx).FlatButtons=fld
    fld=GetPropValue ("FlatSeperators"):if fld>-999 then TabCtrl(ObjTIdx).FlatSeperators=fld
    fld=GetPropValue ("FocusButtons"):if fld>-999 then TabCtrl(ObjTIdx).FocusButtons=fld
    fld=GetPropValue ("HotTrack"):if fld>-999 then TabCtrl(ObjTIdx).HotTrack=fld
    fld=GetPropValue ("MultiLine"):if fld>-999 then TabCtrl(ObjTIdx).MultiLine=fld
    fld=GetPropValue ("ScrollOpposite"):if fld>-999 then TabCtrl(ObjTIdx).ScrollOpposite=fld
    fld=GetPropValue ("TabHeight"):if fld>-999 then TabCtrl(ObjTIdx).TabHeight=fld
    fld=GetPropValue ("TabInactiveColor"):if fld>-999 then TabCtrl(ObjTIdx).TabInactiveColor=fld

    'TabCtrl(ObjTIdx).TabInactiveFont=StrFont(ObjectIndex)
    fld=GetPropValue ("TabIndex"):if fld>-999 then TabCtrl(ObjTIdx).TabIndex=fld
    fld=GetPropValue ("TabPosition"):if fld>-999 then TabCtrl(ObjTIdx).TabPosition=fld
    fld=GetPropValue ("TabWidth"):if fld>-999 then TabCtrl(ObjTIdx).TabWidth=fld
    fld=GetPropValue ("VerticalTabs"):if fld>-999 then TabCtrl(ObjTIdx).VerticalTabs=fld

    'redraw
    'BoxTab(ObjTIdx).visible=false
    BoxTab(ObjTIdx).visible=true
    TabCtrl(ObjTIdx).visible=false
    TabCtrl(ObjTIdx).visible=true'



  CASE "QCOMBOBOX"      '11
    ' Combo(ComboIndex+1)
    'CPan(ComboIndex)
    fld=GetPropValue ("Height"):if fld>-999 then CPan(ObjTIdx).Height=fld
    fld=GetPropValue ("Left"):if fld>-999 then CPan(ObjTIdx).Left=fld
    fld=GetPropValue ("Top"):if fld>-999 then CPan(ObjTIdx).Top=fld
    fld=GetPropValue ("Width"):if fld>-999 then CPan(ObjTIdx).Width=fld

    fld=GetPropValue ("Height"):if fld>-999 then Combo(ObjTIdx).Height=fld
    fld=GetPropValue ("Left"):if fld>-999 then Combo(ObjTIdx).Left=fld
    fld=GetPropValue ("Top"):if fld>-999 then Combo(ObjTIdx).Top=fld
    fld=GetPropValue ("Width"):if fld>-999 then Combo(ObjTIdx).Width=fld



    fld=GetPropValue ("color"):if fld>-999 then Combo(ObjTIdx).color=fld
    fld=GetPropValue ("align"):if fld>-999 then Combo(ObjTIdx).align=fld
    fld=GetPropValue ("cursor"):if fld>-999 then Combo(ObjTIdx).cursor=fld
    fld=GetPropValue ("showhint"):if fld>-999 then Combo(ObjTIdx).showhint=fld
    Combo(ObjTIdx).hint=GetPropString("hint")

    fld=GetPropValue ("DropDownCount"):if fld>-999 then Combo(ObjTIdx).DropDownCount=fld
    fld=GetPropValue ("CopyMode"):if fld>-999 then Combo(ObjTIdx).CopyMode=fld
    fld=GetPropValue ("ItemHeight"):if fld>-999 then Combo(ObjTIdx).ItemHeight=fld
    fld=GetPropValue ("ItemIndex"):if fld>-999 then Combo(ObjTIdx).ItemIndex=fld
    fld=GetPropValue ("MaxLength"):if fld>-999 then Combo(ObjTIdx).MaxLength=fld
    fld=GetPropValue ("Sorted"):if fld>-999 then Combo(ObjTIdx).Sorted=fld
    fld=GetPropValue ("Style"):if fld>-999 then Combo(ObjTIdx).Style=fld
    Combo(ObjTIdx).Text=GetPropString("Text")
    'Combo(ObjTIdx).Enabled=0

    'redraw
    Combo(ObjTIdx).visible=false
    Combo(ObjTIdx).visible=true'
    CPan(ObjTIdx).visible=false
    CPan(ObjTIdx).visible=true


  CASE "QLISTBOX"       '12
    'ListB(ListBIndex+1) AS QLISTBOX

    fld=GetPropValue ("Height"):if fld>-999 then ListB(ObjTIdx).Height=fld
    fld=GetPropValue ("Left"):if fld>-999 then ListB(ObjTIdx).Left=fld
    fld=GetPropValue ("Top"):if fld>-999 then ListB(ObjTIdx).Top=fld
    fld=GetPropValue ("Width"):if fld>-999 then ListB(ObjTIdx).Width=fld

    fld=GetPropValue ("color"):if fld>-999 then ListB(ObjTIdx).color=fld
    fld=GetPropValue ("align"):if fld>-999 then ListB(ObjTIdx).align=fld
    fld=GetPropValue ("cursor"):if fld>-999 then ListB(ObjTIdx).cursor=fld
    fld=GetPropValue ("showhint"):if fld>-999 then ListB(ObjTIdx).showhint=fld
    ListB(ObjTIdx).hint=GetPropString("hint")
    fld=GetPropValue ("Sorted"):if fld>-999 then ListB(ObjTIdx).Sorted=fld
    fld=GetPropValue ("Style"):if fld>-999 then ListB(ObjTIdx).Style=fld
    ListB(ObjTIdx).Text=GetPropString("Text")

    fld=GetPropValue ("Columns"):if fld>-999 then ListB(ObjTIdx).Columns=fld
    'fld=GetPropValue ("Style"):if fld>-999 then ListB(ObjTIdx).CopyMode=fld
    'fld=GetPropValue ("Style"):if fld>-999 then ListB(ObjTIdx).ExtendedSelect=fld
    fld=GetPropValue ("ItemHeight"):if fld>-999 then ListB(ObjTIdx).ItemHeight=fld
    fld=GetPropValue ("ItemIndex"):if fld>-999 then ListB(ObjTIdx).ItemIndex=fld
    'fld=GetPropValue ("Style"):if fld>-999 then ListB(ObjTIdx).MultiSelect=fld
    'fld=GetPropValue ("Style"):if fld>-999 then ListB(ObjTIdx).Sorted=fld
    fld=GetPropValue ("TabWidth"):if fld>-999 then ListB(ObjTIdx).TabWidth=fld
    'fld=GetPropValue ("Style"):if fld>-999 then ListB(ObjTIdx).TopIndex=fld



    'ListB(ObjTIdx).borderstyle=GetPropValue ("borderstyle")
    'propString=AddedObjectList(ObjectIndex)
    'sub SetFIELD(Source$,delim$,fnum%,updField$)
    'sHnd$=str$(ListB(ObjTIdx).Handle)
    'SetFIELD(@propString,"|",3, sHnd$ )
    'AddedObjectList(ObjectIndex)=propString
    ObjectHandle(ObjectIndex)=ListB(ObjTIdx).handle
    'TabCtrl(ObjTIdx).parent=BoxTab(ObjTIdx)

    'redraw
    ListB(ObjTIdx).visible=false
    ListB(ObjTIdx).visible=true'



  CASE "QGROUPBOX"      '13
    'GrpBox(GrpBoxIndex+1) AS QGROUPBOX
    call  AddClrString ("5407:GrpBoxIndex="+str$(GrpBoxIndex), clred, LogEdit)

    fld=GetPropValue ("Height"):if fld>-999 then GrpBox(ObjTIdx).Height=fld
    fld=GetPropValue ("Left"):if fld>-999 then GrpBox(ObjTIdx).Left=fld
    fld=GetPropValue ("Top"):if fld>-999 then GrpBox(ObjTIdx).Top=fld
    fld=GetPropValue ("Width"):if fld>-999 then GrpBox(ObjTIdx).Width=fld
    call  AddClrString ("5413:GrpBox("+str$(ObjTIdx)+"Width)="+str$(GrpBox(ObjTIdx).Width), clred, LogEdit)


    fld=GetPropValue ("align"):if fld>-999 then GrpBox(ObjTIdx).align=fld

    call  AddClrString ("5418:GrpBox("+str$(ObjTIdx)+"align)="+str$(GrpBox(ObjTIdx).align), clred, LogEdit)
    'ObjectHandle(ObjectIndex)=GrpBox(ObjTIdx).handle

    GrpBox(ObjTIdx).caption=GetPropString("caption")
    'exit sub

    fld=GetPropValue ("color"):if fld>-999 then GrpBox(ObjTIdx).color=fld
    fld=GetPropValue ("cursor"):if fld>-999 then GrpBox(ObjTIdx).cursor=fld
    fld=GetPropValue ("showhint"):if fld>-999 then GrpBox(ObjTIdx).showhint=fld
    GrpBox(ObjTIdx).hint=GetPropString("hint")
    'GrpBox(ObjTIdx).Font=StrFont(ObjectIndex)
    ObjectHandle(ObjectIndex)=GrpBox(ObjTIdx).handle

    'redraw
    GrpBox(ObjTIdx).visible=false
    GrpBox(ObjTIdx).visible=true'


  CASE "QSCROLLBOX"     '14
    'reDIM ScrollB(ScrollBIndex+1) AS QSCROLLBOX
    'reDIM BoxInner(ScrollBIndex+1) AS QPANEL                              ' For effect - force scrollbars visible

    fld=GetPropValue ("Height"):if fld>-999 then ScrollB(ObjTIdx).Height=fld
    fld=GetPropValue ("Left"):if fld>-999 then ScrollB(ObjTIdx).Left=fld
    fld=GetPropValue ("Top"):if fld>-999 then ScrollB(ObjTIdx).Top=fld
    fld=GetPropValue ("Width"):if fld>-999 then ScrollB(ObjTIdx).Width=fld

    fld=GetPropValue ("align"):if fld>-999 then ScrollB(ObjTIdx).align=fld
    fld=GetPropValue ("color"):if fld>-999 then ScrollB(ObjTIdx).color=fld
    fld=GetPropValue ("cursor"):if fld>-999 then ScrollB(ObjTIdx).cursor=fld
    fld=GetPropValue ("showhint"):if fld>-999 then ScrollB(ObjTIdx).showhint=fld
    ScrollB(ObjTIdx).hint=GetPropString("hint")

    'fld=GetPropValue ("Width"):if fld>-999 then ScrollB(ObjTIdx).Font=StrFont(ObjectIndex)

    'fld=GetPropValue ("Width"):if fld>-999 then ScrollB(ObjTIdx).AutoScroll=fld)
    fld=GetPropValue ("HorzMargin"):if fld>-999 then ScrollB(ObjTIdx).HorzMargin=fld
    fld=GetPropValue ("HorzPosition"):if fld>-999 then ScrollB(ObjTIdx).HorzPosition=fld
    fld=GetPropValue ("HorzTracking"):if fld>-999 then ScrollB(ObjTIdx).HorzTracking=fld
    fld=GetPropValue ("HorzVisible"):if fld>-999 then ScrollB(ObjTIdx).HorzVisible=fld
    fld=GetPropValue ("VertIncrement"):if fld>-999 then ScrollB(ObjTIdx).VertIncrement=fld
    fld=GetPropValue ("VertMargin"):if fld>-999 then ScrollB(ObjTIdx).VertMargin=fld
    fld=GetPropValue ("VertPosition"):if fld>-999 then ScrollB(ObjTIdx).VertPosition=fld
    fld=GetPropValue ("VertRange"):if fld>-999 then ScrollB(ObjTIdx).VertRange=fld
    fld=GetPropValue ("VertTracking"):if fld>-999 then ScrollB(ObjTIdx).VertTracking=fld
    fld=GetPropValue ("VertVisible"):if fld>-999 then ScrollB(ObjTIdx).VertVisible=fld

    'ScrollB(ObjTIdx).BorderStyle=GetPropValue("BorderStyle")
    ObjectHandle(ObjectIndex)=ScrollB(ObjTIdx).handle
    'TabCtrl(ObjTIdx).parent=BoxTab(ObjTIdx)

    brem 0
    erem

    'redraw
    ScrollB(ObjTIdx).visible=false
    ScrollB(ObjTIdx).visible=true'



  CASE "QSCROLLBAR"     '15

    'reDIM ScrollBar(ScrllBarIndex+1) AS QSCROLLBAR

    fld=GetPropValue ("align"):if fld>-999 then ScrollBar(ObjTIdx).align=fld
    'call  AddClrString ("3973:ScrollBar("+str$(ObjTIdx)+"kind)="+str$(ScrollBar(ObjTIdx).kind), clb, LogEdit)
    fld=GetPropValue ("cursor"):if fld>-999 then ScrollBar(ObjTIdx).cursor=fld
    fld=GetPropValue ("showhint"):if fld>-999 then ScrollBar(ObjTIdx).showhint=fld
    ScrollBar(ObjTIdx).hint=GetPropString("hint")

    fld=GetPropValue ("top"):if fld>-999 then ScrollBar(ObjTIdx).top=fld
    fld=GetPropValue ("left"):if fld>-999 then ScrollBar(ObjTIdx).left=fld
    fld=GetPropValue ("height"):if fld>-999 then ScrollBar(ObjTIdx).height=fld
    fld=GetPropValue ("width"):if fld>-999 then ScrollBar(ObjTIdx).width=fld
    fld=GetPropValue ("kind"):if fld>-999 then ScrollBar(ObjTIdx).kind=fld
    'redraw
    ScrollBar(ObjTIdx).visible=false
    ScrollBar(ObjTIdx).visible=true'

    'PageSize
    'Position

  CASE "QSTRINGGRID"    '16
    'reDIM StrGrid(StringGIndex+1) AS QLISTVIEW

    fld=GetPropValue ("Height"):if fld>-999 then StrGrid(ObjTIdx).Height=fld
    fld=GetPropValue ("Left"):if fld>-999 then StrGrid(ObjTIdx).Left=fld
    fld=GetPropValue ("Top"):if fld>-999 then StrGrid(ObjTIdx).Top=fld
    fld=GetPropValue ("Width"):if fld>-999 then StrGrid(ObjTIdx).Width=fld


    fld=GetPropValue ("align"):if fld>-999 then StrGrid(ObjTIdx).align=fld
    'GrpBox(ObjTIdx).caption=GetPropString("caption")
    fld=GetPropValue ("color"):if fld>-999 then StrGrid(ObjTIdx).color=fld
    fld=GetPropValue ("cursor"):if fld>-999 then StrGrid(ObjTIdx).cursor=fld
    fld=GetPropValue ("showhint"):if fld>-999 then StrGrid(ObjTIdx).showhint=fld
    StrGrid(ObjTIdx).hint=GetPropString("hint")
    'GrpBox(ObjTIdx).Font=StrFont(ObjectIndex)
    'DefaultColWidth
    'DefaultRowHeight
    'EditorMode
    'FixedColor
    'FixedCols
    'FixedRows
    'Font
    'GridHeight
    'GridLineWidth
    'GridWidth
    'LeftCol
    'RowCount
    'ScrollBars
    'VisibleColCount


    'redraw
    StrGrid(ObjTIdx).visible=false
    StrGrid(ObjTIdx).visible=true'


  CASE "QLISTVIEW"      '17
    fld=GetPropValue ("Height"):if fld>-999 then ListView(ObjTIdx).Height=fld
    fld=GetPropValue ("Left"):if fld>-999 then ListView(ObjTIdx).Left=fld
    fld=GetPropValue ("Top"):if fld>-999 then ListView(ObjTIdx).Top=fld
    fld=GetPropValue ("Width"):if fld>-999 then ListView(ObjTIdx).Width=fld


    fld=GetPropValue ("align"):if fld>-999 then ListView(ObjTIdx).align=fld
    'ListView(ObjTIdx).caption=GetPropString("caption")
    fld=GetPropValue ("color"):if fld>-999 then ListView(ObjTIdx).color=fld
    fld=GetPropValue ("cursor"):if fld>-999 then ListView(ObjTIdx).cursor=fld
    fld=GetPropValue ("showhint"):if fld>-999 then ListView(ObjTIdx).showhint=fld
    ListView(ObjTIdx).hint=GetPropString("hint")
    'GrpBox(ObjTIdx).Font=StrFont(ObjectIndex)

    'redraw
    ListView(ObjTIdx).visible=false
    ListView(ObjTIdx).visible=true'

  CASE "QDIRTREE"       '18

    fld=GetPropValue ("align"):if fld>-999 then BoxDTree(ObjTIdx).align=fld'GetPropValue ("align")
    fld=GetPropValue ("BorderStyle"):if fld>-999 then BoxDTree(ObjTIdx).showhint=fld'GetPropValue ("BorderStyle")
    fld=GetPropValue ("Color"):if fld>-999 then BoxDTree(ObjTIdx).Color=fld 'GetPropValue ("Color")
    fld=GetPropValue ("cursor"):if fld>-999 then BoxDTree(ObjTIdx).cursor=fld'GetPropValue ("cursor")
    fld=GetPropValue ("showhint"):if fld>-999 then BoxDTree(ObjTIdx).showhint=fld'GetPropValue ("showhint")
    'fld=GetPropValue ("Directory"):if fld>-999 then BoxDTree(ObjTIdx).showhint=GetPropValue ("Directory")
    'fld=GetPropValue ("Enabled"):if fld>-999 then BoxDTree(ObjTIdx).Enabled=fld'GetPropValue ("Enabled")
    'fld=GetPropValue ("HideSelection"):if fld>-999 then BoxDTree(ObjTIdx).showhint=fld'GetPropValue ("Color")
    'fld=GetPropValue ("Color"):if fld>-999 then BoxDTree(ObjTIdx).showhint=GetPropValue ("Color")
    'fld=GetPropValue ("Color"):if fld>-999 then BoxDTree(ObjTIdx).showhint=GetPropValue ("Color")

    BoxDTree(ObjTIdx).hint=GetPropString("hint")
    'BoxDTree(ObjTIdx).Directory=GetPropString("Directory")

    fld=GetPropValue ("top"):if fld>-999 then BoxDTree(ObjTIdx).top=fld
    call  AddClrString ("5706:BoxDTree("+str$(ObjTIdx)+"top)="+str$(BoxDTree(ObjTIdx).top), &H6B0000, LogEdit)
    fld=GetPropValue ("left"):if fld>-999 then BoxDTree(ObjTIdx).left=fld
    call  AddClrString ("5708:BoxDTree("+str$(ObjTIdx)+"left)="+str$(BoxDTree(ObjTIdx).left), &H6B0000, LogEdit)
    fld=GetPropValue ("height"):if fld>-999 then BoxDTree(ObjTIdx).height=fld
    call  AddClrString ("5710:BoxDTree("+str$(ObjTIdx)+"height)="+str$(BoxDTree(ObjTIdx).height), &H6B0000, LogEdit)
    fld=GetPropValue ("width"):if fld>-999 then BoxDTree(ObjTIdx).width=fld
    call  AddClrString ("5712:BoxDTree("+str$(ObjTIdx)+"width)="+str$(BoxDTree(ObjTIdx).width), &H6B0000, LogEdit)
    'redraw
    BoxDTree(ObjTIdx).visible=false
    BoxDTree(ObjTIdx).visible=true'

  CASE "QFILELISTBOX"   '19

    'reDIM dFileL(FileLindex+1) AS QFILELISTBOX
    'reDIM BoxFile(FileLindex+1) AS QPANEL

    fld=GetPropValue ("Height"):if fld>-999 then BoxFile(ObjTIdx).Height=fld
    'call  AddClrString ("4072:BoxFile("+str$(ObjTIdx)+"Height)="+str$(BoxFile(ObjTIdx).Height), clred, LogEdit)
    fld=GetPropValue ("Left"):if fld>-999 then BoxFile(ObjTIdx).Left=fld
    fld=GetPropValue ("Top"):if fld>-999 then BoxFile(ObjTIdx).Top=fld
    fld=GetPropValue ("Width"):if fld>-999 then BoxFile(ObjTIdx).Width=fld
    dFileL(ObjTIdx).align=alClient

    'GrpBox(ObjTIdx).caption=GetPropString("caption")
    fld=GetPropValue ("color"):if fld>-999 then dFileL(ObjTIdx).color=fld
    fld=GetPropValue ("cursor"):if fld>-999 then dFileL(ObjTIdx).cursor=fld
    fld=GetPropValue ("showhint"):if fld>-999 then dFileL(ObjTIdx).showhint=fld
    dFileL(ObjTIdx).hint=GetPropString("hint")

    'fld=GetPropValue ("align"):if fld>-999 then BoxFile(ObjTIdx).align=fld

    'fld=GetPropValue ("Directory"):if fld>-999 then dFileL(ObjTIdx).Directory=fld
    'fld=GetPropValue ("Drive"):if fld>-999 then dFileL(ObjTIdx).Drive=fld
    'fld=GetPropValue ("ItemHeight"):if fld>-999 then dFileL(ObjTIdx).ItemHeight=fld
    'fld=GetPropValue ("ShowIcons"):if fld>-999 then dFileL(ObjTIdx).ShowIcons=fld
    'fld=GetPropValue ("TopIndex"):if fld>-999 then dFileL(ObjTIdx).TopIndex=fld

    'Directory
    'ItemHeight



    'GrpBox(ObjTIdx).Font=StrFont(ObjectIndex)

    'redraw
    BoxFile(ObjTIdx).visible=false
    BoxFile(ObjTIdx).visible=true'

  CASE "QTREEVIEW"      '20
    fld=GetPropValue ("Height"):if fld>-999 then BoxTree(ObjTIdx).Height=fld else BoxTree(ObjTIdx).Height=97
    fld=GetPropValue ("Left"):if fld>-999 then BoxTree(ObjTIdx).Left=fld
    fld=GetPropValue ("Top"):if fld>-999 then BoxTree(ObjTIdx).Top=fld
    fld=GetPropValue ("Width"):if fld>-999 then BoxTree(ObjTIdx).Width=fld else BoxTree(ObjTIdx).Height=120


    fld=GetPropValue ("align"):if fld>-999 then BoxTree(ObjTIdx).align=fld
    BoxTree(ObjTIdx).caption=GetPropString("caption")
    fld=GetPropValue ("color"):if fld>-999 then BoxTree(ObjTIdx).color=fld
    fld=GetPropValue ("cursor"):if fld>-999 then BoxTree(ObjTIdx).cursor=fld
    fld=GetPropValue ("showhint"):if fld>-999 then BoxTree(ObjTIdx).showhint=fld
    BoxTree(ObjTIdx).hint=GetPropString("hint")
    'GrpBox(ObjTIdx).Font=StrFont(ObjectIndex)

    'redraw
    BoxTree(ObjTIdx).visible=false
    BoxTree(ObjTIdx).visible=true'

  CASE "QOUTLINE"       '21
    'BoxOutLine(OutLnIndex)
    fld=GetPropValue ("Height"):if fld>-999 then BoxOutLine(ObjTIdx).Height=fld else BoxOutLine(ObjTIdx).Height=100
    fld=GetPropValue ("Left"):if fld>-999 then BoxOutLine(ObjTIdx).Left=fld
    fld=GetPropValue ("Top"):if fld>-999 then BoxOutLine(ObjTIdx).Top=fld
    fld=GetPropValue ("Width"):if fld>-999 then BoxOutLine(ObjTIdx).Width=fld else BoxOutLine(ObjTIdx).Width=100


    fld=GetPropValue ("align"):if fld>-999 then BoxOutLine(ObjTIdx).align=fld

    'fld$=GetPropString("BMPClosed"):if fld$<>"" then frmOutLine(ObjTIdx).BMPClosed=fld$
    'fld$=GetPropString("BMPMinus"):if fld$<>"" then frmOutLine(ObjTIdx).BMPMinus=fld$
    'fld$=GetPropString("BMPOpen"):if fld$<>"" then frmOutLine(ObjTIdx).BMPOpen=fld$
    'fld$=GetPropString("BMPPlus"):if fld$<>"" then frmOutLine(ObjTIdx).BMPPlus=fld$
    'fld$=GetPropString("BMPBMPHandleClosed"):if fld$<>"" then frmOutLine(ObjTIdx).BMPHandleClosed=fld$
    'fld$=GetPropString("BMPHandleLeaf"):if fld$<>"" then frmOutLine(ObjTIdx).BMPHandleLeaf=fld$
    'fld$=GetPropString("BMPHandleMinus"):if fld$<>"" then frmOutLine(ObjTIdx).BMPHandleMinus=fld$
    'fld$=GetPropString("BMPHandleOpen"):if fld$<>"" then frmOutLine(ObjTIdx).BMPHandleOpen=fld$
    'fld$=GetPropString("BMPHandlePlus"):if fld$<>"" then frmOutLine(ObjTIdx).BMPHandlePlus=fld$


    'fld=GetPropValue ("color"):if fld>-999 then frmOutLine(ObjTIdx).color=fld
    fld=GetPropValue ("cursor"):if fld>-999 then BoxOutLine(ObjTIdx).cursor=fld
    fld=GetPropValue ("showhint"):if fld>-999 then BoxOutLine(ObjTIdx).showhint=fld
    BoxOutLine(ObjTIdx).hint=GetPropString("hint")
    'BoxOutLine(ObjTIdx).Font=StrFont(ObjectIndex)

    'fld=GetPropValue ("ItemHeight"):if fld>-999 then frmOutLine(ObjTIdx).ItemHeight=fld
    'fld=GetPropValue ("LineCount"):if fld>-999 then BoxOutLine(ObjTIdx).LineCount=fld
    'fld=GetPropValue ("OutLineStyle"):if fld>-999 then BoxOutLine(ObjTIdx).OutLineStyle=fld
    'fld=GetPropValue ("ScrollBars"):if fld>-999 then BoxOutLine(ObjTIdx).ScrollBars=fld
    'fld$=GetPropString("ItemSeparator"):if fld$<>"" then frmOutLine(ObjTIdx).ItemSeparator=fld$

    'redraw
    BoxOutLine(ObjTIdx).visible=false
    BoxOutLine(ObjTIdx).visible=true'

  CASE "QGAUGE"         '22
    'DIM dGauge(GaugeIndex+1) AS QGAUGE
    'DIM panGauge(GaugeIndex+1) AS QPANEL

    fld=GetPropValue ("Height"):if fld>-999 then panGauge(ObjTIdx).Height=fld
    ''call  AddClrString ("4189:panGauge("+str$(ObjTIdx)+"Height)="+str$(panGauge(ObjTIdx).Height), clb, LogEdit)
    fld=GetPropValue ("Left"):if fld>-999 then panGauge(ObjTIdx).Left=fld
    fld=GetPropValue ("Top"):if fld>-999 then panGauge(ObjTIdx).Top=fld
    ''call  AddClrString ("4192:panGauge("+str$(ObjTIdx)+"Top)="+str$(panGauge(ObjTIdx).Top), clb, LogEdit)
    fld=GetPropValue ("Width"):if fld>-999 then panGauge(ObjTIdx).Width=fld

    'brem 0
    '================bv
    fld=GetPropValue ("align"):if fld>-999 then panGauge(ObjTIdx).align=fld
    panGauge(ObjTIdx).caption=GetPropString("caption")
    fld=GetPropValue ("color"):if fld>-999 then dGauge(ObjTIdx).color=fld
    fld=GetPropValue ("cursor"):if fld>-999 then panGauge(ObjTIdx).cursor=fld
    fld=GetPropValue ("showhint"):if fld>-999 then panGauge(ObjTIdx).showhint=fld
    panGauge(ObjTIdx).hint=GetPropString("hint")
    'panGauge(ObjTIdx).Font=StrFont(ObjectIndex)
    fld=GetPropValue ("BackColor"):if fld>-999 then dGauge(ObjTIdx).BackColor=fld
    fld=GetPropValue ("ForeColor"):if fld>-999 then dGauge(ObjTIdx).ForeColor=fld
    fld=GetPropValue ("Kind"):if fld>-999 then dGauge(ObjTIdx).Kind=fld
    fld=GetPropValue ("Max"):if fld>-999 then dGauge(ObjTIdx).Max=fld
    fld=GetPropValue ("Min"):if fld>-999 then dGauge(ObjTIdx).Min=fld
    fld=GetPropValue ("Position"):if fld>-999 then dGauge(ObjTIdx).Position=fld
    fld=GetPropValue ("ShowText"):if fld>-999 then dGauge(ObjTIdx).ShowText=fld
    '========
    'erem
    'redraw
    'panGauge(ObjTIdx).visible=false
    'panGauge(ObjTIdx).visible=true'


  CASE "QTRACKBAR"      '23
    'reDIM dTrackBar(TrackBIndex+1) AS QTRACKBAR

    fld=GetPropValue ("align"):if fld>-999 then dTrackBar(ObjTIdx).align=fld
    'GrpBox(ObjTIdx).caption=GetPropString("caption")
    'fld=GetPropValue ("color"):if fld>-999 then GrpBox(ObjTIdx).color=GetPropValue ("color")
    fld=GetPropValue ("cursor"):if fld>-999 then dTrackBar(ObjTIdx).cursor=fld
    fld=GetPropValue ("showhint"):if fld>-999 then dTrackBar(ObjTIdx).showhint=fld
    dTrackBar(ObjTIdx).hint=GetPropString("hint")
    'GrpBox(ObjTIdx).Font=StrFont(ObjectIndex)
    fld=GetPropValue ("Frequency"):if fld>-999 then dTrackBar(ObjTIdx).Frequency=fld
    fld=GetPropValue ("Max"):if fld>-999 then dTrackBar(ObjTIdx).Max=fld
    fld=GetPropValue ("Min"):if fld>-999 then dTrackBar(ObjTIdx).Min=fld
    fld=GetPropValue ("Orientation"):if fld>-999 then dTrackBar(ObjTIdx).Orientation=fld
    fld=GetPropValue ("PageSize"):if fld>-999 then dTrackBar(ObjTIdx).PageSize=fld
    fld=GetPropValue ("Position"):if fld>-999 then dTrackBar(ObjTIdx).Position=fld
    fld=GetPropValue ("TickMarks"):if fld>-999 then dTrackBar(ObjTIdx).TickMarks=fld
    fld=GetPropValue ("TickStyle"):if fld>-999 then dTrackBar(ObjTIdx).TickStyle=fld
    'redraw
    fld=GetPropValue ("Height"):if fld>-999 then dTrackBar(ObjTIdx).Height=fld
    fld=GetPropValue ("Left"):if fld>-999 then dTrackBar(ObjTIdx).Left=fld
    fld=GetPropValue ("Top"):if fld>-999 then dTrackBar(ObjTIdx).Top=fld
    fld=GetPropValue ("Width"):if fld>-999 then dTrackBar(ObjTIdx).Width=fld

    dTrackBar(ObjTIdx).visible=false
    dTrackBar(ObjTIdx).visible=true'
    ObjectHandle(ObjectIndex)=dTrackBar(TrackBIndex).Handle


  CASE "QHEADER"        '24

    'reDIM Headr(HeadIndex+1) AS QHEADER
    'reDIM BoxHeadr(HeadIndex+1) AS QPANEL

    fld=GetPropValue ("Height"):if fld>-999 then BoxHeadr(ObjTIdx).Height=fld
    fld=GetPropValue ("Left"):if fld>-999 then BoxHeadr(ObjTIdx).Left=fld
    fld=GetPropValue ("Top"):if fld>-999 then BoxHeadr(ObjTIdx).Top=fld
    fld=GetPropValue ("Width"):if fld>-999 then BoxHeadr(ObjTIdx).Width=fld


    fld=GetPropValue ("align"):if fld>-999 then BoxHeadr(ObjTIdx).align=fld
    'GrpBox(ObjTIdx).caption=GetPropString("caption")
    fld=GetPropValue ("cursor"):if fld>-999 then BoxHeadr(ObjTIdx).cursor=fld
    fld=GetPropValue ("showhint"):if fld>-999 then BoxHeadr(ObjTIdx).showhint=fld
    BoxHeadr(ObjTIdx).hint=GetPropString("hint")
    'GrpBox(ObjTIdx).Font=StrFont(ObjectIndex)
    fld=GetPropValue ("HotTrack"):if fld>-999 then Headr(ObjTIdx).HotTrack=fld

    'redraw
    BoxHeadr(ObjTIdx).visible=false
    BoxHeadr(ObjTIdx).visible=true'

  CASE "QSTATUSBAR"     '25
    'DIM StatBar(32) AS QSTATUSBAR
    'DIM BoxStat(32) AS QPANEL

    fld=GetPropValue ("Height"):if fld>-999 then BoxStat(ObjTIdx).Height=fld
    fld=GetPropValue ("Left"):if fld>-999 then BoxStat(ObjTIdx).Left=fld
    fld=GetPropValue ("Top"):if fld>-999 then BoxStat(ObjTIdx).Top=fld
    fld=GetPropValue ("Width"):if fld>-999 then BoxStat(ObjTIdx).Width=fld


    fld=GetPropValue ("align"):if fld>-999 then BoxStat(ObjTIdx).align=fld
    'GrpBox(ObjTIdx).caption=GetPropString("caption")
    fld=GetPropValue ("color"):if fld>-999 then BoxStat(ObjTIdx).color=fld
    fld=GetPropValue ("cursor"):if fld>-999 then BoxStat(ObjTIdx).cursor=fld
    fld=GetPropValue ("showhint"):if fld>-999 then BoxStat(ObjTIdx).showhint=fldhg
    BoxStat(ObjTIdx).hint=GetPropString("hint")
    'GrpBox(ObjTIdx).Font=StrFont(ObjectIndex)
    'SimplePanel
    'SimpleText
    'SizeGrip


    'redraw
    BoxStat(ObjTIdx).visible=false
    BoxStat(ObjTIdx).visible=true'

  CASE "QCANVAS"        '26

    'reDIM panCanv(CanvasIndex+1) AS QPANEL
    'reDIM Canv(CanvasIndex+1) AS QCanvas

    fld=GetPropValue ("Height"):if fld>-999 then panCanv(ObjTIdx).Height=fld
    fld=GetPropValue ("Left"):if fld>-999 then panCanv(ObjTIdx).Left=fld
    fld=GetPropValue ("Top"):if fld>-999 then panCanv(ObjTIdx).Top=fld
    fld=GetPropValue ("Width"):if fld>-999 then panCanv(ObjTIdx).Width=fld

    fld=GetPropValue ("align"):if fld>-999 then panCanv(ObjTIdx).align=fld
    'panCanv(ObjTIdx).caption=GetPropString("caption")
    fld=GetPropValue ("color"):if fld>-999 then panCanv(ObjTIdx).color=fld
    'call  AddClrString ("4315:panCanv("+str$(ObjTIdx)+"color)="+str$(panCanv(ObjTIdx).color), clb, LogEdit)
    fld=GetPropValue ("cursor"):if fld>-999 then panCanv(ObjTIdx).cursor=fld
    fld=GetPropValue ("showhint"):if fld>-999 then panCanv(ObjTIdx).showhint=fld
    'fld=GetPropValue ("onpaint"):if fld>-999 then Canv(ObjTIdx).onpaint=fld
    panCanv(ObjTIdx).hint=GetPropString("hint")
    'Canv(ObjTIdx).onpaint=GetPropString("onpaint")
    'Canv(ObjTIdx).color=fld
    'Canv(ObjTIdx).Font=StrFont(ObjectIndex)

    'redraw
    panCanv(ObjTIdx).visible=false
    panCanv(ObjTIdx).visible=true'

  CASE "QIMAGE"         '27

    'DIM Imag(32) AS QImage
    'DIM panImage(32) AS QPANEL

    fld=GetPropValue ("Height"):if fld>-999 then panImage(ObjTIdx).Height=fld else panImage(ObjTIdx).Height=100
    fld=GetPropValue ("Left"):if fld>-999 then panImage(ObjTIdx).Left=fld
    fld=GetPropValue ("Top"):if fld>-999 then panImage(ObjTIdx).Top=fld
    fld=GetPropValue ("Width"):if fld>-999 then panImage(ObjTIdx).Width=fld else panImage(ObjTIdx).Width=100

    fld=GetPropValue ("align"):if fld>-999 then panImage(ObjTIdx).align=fld
    'panImage(ObjTIdx).caption=GetPropString("caption")
    fld=GetPropValue ("color"):if fld>-999 then panImage(ObjTIdx).color=fld  else panImage(ObjTIdx).color=clm

    fld=GetPropValue ("cursor"):if fld>-999 then panImage(ObjTIdx).cursor=fld
    fld=GetPropValue ("showhint"):if fld>-999 then panImage(ObjTIdx).showhint=fld
    panImage(ObjTIdx).hint=GetPropString("hint")
    'panImage(ObjTIdx).Font=StrFont(ObjectIndex)
    fld=GetPropValue ("Autosize"):if fld>-999 then Imag(ObjTIdx).Autosize=fld
    fld=GetPropValue ("Center"):if fld>-999 then Imag(ObjTIdx).Center=fld
    fld=GetPropValue ("Stretch"):if fld>-999 then Imag(ObjTIdx).Stretch=fld
    fld=GetPropValue ("Transparent"):if fld>-999 then Imag(ObjTIdx).Transparent=fld else Imag(ObjTIdx).Transparent=1

    fld$=GetPropString ("BMP"):if fld$<>"" then Imag(ObjTIdx).BMP=fld$-qt
    'call  AddClrString ("4369:fld$="+(fld$), clb, LogEdit)

    'redraw
    panImage(ObjTIdx).visible=false
    panImage(ObjTIdx).visible=true'
    Imag(ObjTIdx).visible=false
    Imag(ObjTIdx).visible=true'

  CASE "QOLECONTAINER"  '28
    fld=GetPropValue ("Height"):if fld>-999 then oleContainer(ObjTIdx).Height=fld else oleContainer(ObjTIdx).Height=100

    fld=GetPropValue ("Left"):if fld>-999 then oleContainer(ObjTIdx).Left=fld
    fld=GetPropValue ("Top"):if fld>-999 then oleContainer(ObjTIdx).Top=fld
    fld=GetPropValue ("Width"):if fld>-999 then oleContainer(ObjTIdx).Width=fld else oleContainer(ObjTIdx).Width=100



    fld=GetPropValue ("align"):if fld>-999 then oleContainer(ObjTIdx).align=GetPropValue ("align")
    oleContainer(ObjTIdx).caption="QOleContainer("+str$(ObjTIdx)+")"
    'GetPropString("caption")
    fld=GetPropValue ("color"):if fld>-999 then oleContainer(ObjTIdx).color=GetPropValue ("color")
    fld=GetPropValue ("cursor"):if fld>-999 then oleContainer(ObjTIdx).cursor=GetPropValue ("cursor")
    fld=GetPropValue ("showhint"):if fld>-999 then oleContainer(ObjTIdx).showhint=GetPropValue ("showhint")
    oleContainer(ObjTIdx).hint=GetPropString("hint")
    'oleContainer(ObjTIdx).Font=StrFont(ObjectIndex)

    'redraw
    oleContainer(ObjTIdx).visible=false
    oleContainer(ObjTIdx).visible=true'
  CASE "QSPLITTER"      '29
    fld=GetPropValue ("Height"):if fld>-999 then panSplit(ObjTIdx).Height=fld
    fld=GetPropValue ("Left"):if fld>-999 then panSplit(ObjTIdx).Left=fld
    fld=GetPropValue ("Top"):if fld>-999 then panSplit(ObjTIdx).Top=fld
    fld=GetPropValue ("Width"):if fld>-999 then panSplit(ObjTIdx).Width=fld


    fld=GetPropValue ("align"):if fld>-999 then panSplit(ObjTIdx).align=GetPropValue ("align")
    panSplit(ObjTIdx).caption=GetPropString("caption")
    fld=GetPropValue ("color"):if fld>-999 then panSplit(ObjTIdx).color=GetPropValue ("color")
    fld=GetPropValue ("cursor"):if fld>-999 then panSplit(ObjTIdx).cursor=GetPropValue ("cursor")
    fld=GetPropValue ("showhint"):if fld>-999 then panSplit(ObjTIdx).showhint=GetPropValue ("showhint")
    panSplit(ObjTIdx).hint=GetPropString("hint")
    'panSplit(ObjTIdx).Font=StrFont(ObjectIndex)

    'redraw
    panSplit(ObjTIdx).visible=false
    panSplit(ObjTIdx).visible=true'

  end select
  'ReDrawComponent
  '!!! BuildFormCode

end sub


'*****************************************
SUB ReDrawComponentbyField_OLD
  DEFSTR propString, token, tstr, cap
  DEFINT i, X, Y, Height, Width, objType, reposn,ObjTIdx
  DEFLNG hWnd
  DIM rect AS QRECT

  defint rowi, ci
  defstr celli
  defstr const_i

  propString=AddedObjectList(CurrentObject)
  'call  AddClrString ("2467:propString="+(propString), clo, LogEdit)
  tstr=FIELD$(propString,"~",1)
  'call  AddClrString ("2469:tstr="+(tstr), clb, LogEdit)
  objType=VAL(FIELD$(tstr,"|",1))
  'call  AddClrString ("2471:objType="+str$(objType), clp, LogEdit)
  IF objType>=NON_VISIBLE THEN EXIT SUB

  ObjTIdx=ObjTypeIndex(CurrentObject)
  if ObjTIdx>100 then exit sub

  ' Visible components
  SELECT CASE objType ' SUB ReDrawComponentbyField

  CASE Q_FORM          '0

    Forms(ObjTIdx).color=GetPropValue ("color")
    Forms(ObjTIdx).AutoScroll=GetPropValue ("AutoScroll")
    'Forms(ObjTIdx).BorderStyle=GetPropValue ("BorderStyle")
    Forms(ObjTIdx).Cursor=GetPropValue ("Cursor")
    Forms(ObjTIdx).Font=StrFont(CurrentObject)
    'Forms(ObjTIdx).FormStyle=GetPropValue ("FormStyle")
    Forms(ObjTIdx).Hint=GetPropValue ("Hint")
    Forms(ObjTIdx).KeyPreview=GetPropValue ("KeyPreview")
    Forms(ObjTIdx).ModalResult=GetPropValue ("ModalResult")
    Forms(ObjTIdx).ShowHint=GetPropValue ("ShowHint")
    'Forms(ObjTIdx).Visible=GetPropValue ("Visible")
    'Forms(ObjTIdx).WindowState=GetPropValue ("WindowState")


  CASE Q_EDIT          '1
    call  AddClrString ("2450:Q_EDIT="+str$(Q_EDIT), clm, LogEdit)

    hWnd=BoxEdit(ObjTIdx).Handle
    BoxEdit(ObjTIdx).BevelOuter=GetPropValue ("borderstyle")' BevelOuter
    BoxEdit(ObjTIdx).color=GetPropValue ("color")
    BoxEdit(ObjTIdx).align=GetPropValue ("align")
    BoxEdit(ObjTIdx).caption=GetPropString("text")  ' GetPropValue ("text")
    BoxEdit(ObjTIdx).cursor=GetPropValue ("cursor")
    BoxEdit(ObjTIdx).showhint=GetPropValue ("showhint")
    BoxEdit(ObjTIdx).hint=GetPropString("hint")
    BoxEdit(ObjTIdx).Font=StrFont(CurrentObject) '!!! Исправить - каждому компоненту отдельный шрифт

    'redraw
    BoxEdit(ObjTIdx).visible=false
    BoxEdit(ObjTIdx).visible=true'

  CASE Q_RICHEDIT      '2
    BoxRICH(ObjTIdx).BevelOuter=GetPropValue ("borderstyle")' BevelOuter
    BoxRICH(ObjTIdx).color=GetPropValue ("color")
    BoxRICH(ObjTIdx).Alignment=GetPropValue ("alignment")
    BoxRICH(ObjTIdx).align=GetPropValue ("align")
    BoxRICH(ObjTIdx).caption=GetPropString ("text")

    BoxRICH(ObjTIdx).cursor=GetPropValue ("cursor")
    BoxRICH(ObjTIdx).showhint=GetPropValue ("showhint")
    BoxRICH(ObjTIdx).hint=GetPropString("hint")
    BoxRICH(ObjTIdx).Font=StrFont(CurrentObject)

    'redraw
    BoxRICH(ObjTIdx).visible=false
    BoxRICH(ObjTIdx).visible=true'


  CASE Q_LABEL         '3 BoxLabel(1)

    BoxLabel(ObjTIdx).BevelOuter=0'GetPropValue ("borderstyle")' BevelOuter
    BoxLabel(ObjTIdx).color=GetPropValue ("color")
    BoxLabel(ObjTIdx).align=GetPropValue ("align")
    BoxLabel(ObjTIdx).alignment=GetPropValue ("alignment")
    BoxLabel(ObjTIdx).cursor=GetPropValue ("cursor")
    BoxLabel(ObjTIdx).showhint=GetPropValue ("showhint")
    BoxLabel(ObjTIdx).hint=GetPropString("hint")
    BoxLabel(ObjTIdx).Font=StrFont(CurrentObject)
    BoxLabel(ObjTIdx).caption=GetPropString ("caption")
    'redraw
    BoxLabel(ObjTIdx).visible=false
    BoxLabel(ObjTIdx).visible=true'


  CASE Q_BUTTON        '4

    boxBut(ObjTIdx).caption=GetPropString ("caption")' BevelOuter
    boxBut(ObjTIdx).color=GetPropValue ("color")
    boxBut(ObjTIdx).align=GetPropValue ("align")
    boxBut(ObjTIdx).enabled=GetPropValue ("enabled")
    boxBut(ObjTIdx).cursor=GetPropValue ("cursor")
    boxBut(ObjTIdx).showhint=GetPropValue ("showhint")
    boxBut(ObjTIdx).hint=GetPropString("hint")
    boxBut(ObjTIdx).Font=StrFont(CurrentObject)

    'redraw
    boxBut(ObjTIdx).visible=false
    boxBut(ObjTIdx).visible=true'


  CASE Q_COOLBTN       '5
  CASE Q_OVALBTN       '6
  CASE Q_CHECKBOX      '7
  CASE Q_RADIOBUTTON   '8

  CASE Q_PANEL         '9

    dPan(ObjTIdx).bevelinner=GetPropValue ("bevelinner")
    dPan(ObjTIdx).bevelouter=GetPropValue ("bevelouter")
    dPan(ObjTIdx).bevelwidth=GetPropValue ("bevelwidth")

    dPan(ObjTIdx).align=GetPropValue ("align")
    dPan(ObjTIdx).alignment=GetPropValue ("alignment")

    'dPan(ObjTIdx).borderstyle=GetPropValue ("borderstyle")
    brem 0
    ' обновляем handle
    propString=AddedObjectList(CurrentObject)
    'sub SetFIELD(Source$,delim$,fnum%,updField$)
    sHnd$=str$(dPan(ObjTIdx).Handle)
    SetFIELD(@propString,"|",3, sHnd$ )
    AddedObjectList(CurrentObject)=propString
    erem

    dPan(ObjTIdx).caption=GetPropString ("caption")' BevelOuter
    dPan(ObjTIdx).color=GetPropValue ("color")
    dPan(ObjTIdx).cursor=GetPropValue ("cursor")
    dPan(ObjTIdx).showhint=GetPropValue ("showhint")
    dPan(ObjTIdx).hint=GetPropString("hint")
    dPan(ObjTIdx).Font=StrFont(CurrentObject)

    'redraw
    dPan(ObjTIdx).visible=false
    dPan(ObjTIdx).visible=true'


  CASE Q_TABCONTROL    '10
    'TabCtrl(TabContIndex+1) AS QTABCONTROL

    TabCtrl(ObjTIdx).color=GetPropValue ("color")
    BoxTab(ObjTIdx).align=GetPropValue ("align")
    TabCtrl(ObjTIdx).cursor=GetPropValue ("cursor")
    TabCtrl(ObjTIdx).showhint=GetPropValue ("showhint")
    TabCtrl(ObjTIdx).hint=GetPropString("hint")

    TabCtrl(ObjTIdx).Font=StrFont(CurrentObject)
    'TabCtrl(ObjTIdx).ButtonStyle=GetPropValue (("buttonStyle"))
    TabCtrl(ObjTIdx).FlatButtons=GetPropValue ("FlatButtons")
    TabCtrl(ObjTIdx).FlatSeperators=GetPropValue ("FlatSeperators")
    TabCtrl(ObjTIdx).FocusButtons=GetPropValue ("FocusButtons")
    TabCtrl(ObjTIdx).HotTrack=GetPropValue ("HotTrack")
    TabCtrl(ObjTIdx).MultiLine=GetPropValue ("MultiLine")
    TabCtrl(ObjTIdx).ScrollOpposite=GetPropValue ("ScrollOpposite")
    TabCtrl(ObjTIdx).TabHeight=GetPropValue ("TabHeight")
    TabCtrl(ObjTIdx).TabInactiveColor=GetPropValue ("TabInactiveColor")
    BoxTab(ObjTIdx).visible=GetPropValue ("visible")

    ' обновляем handle

    'btn.Visible=False: btn.Parent=TabCtrl(TabContIndex)
    'TabHandle=GetParent(btn.Handle)
    'call  AddClrString ("2633:TabHandle="+str$(TabHandle), clp, LogEdit)
    'DestroyWindow(btn.Handle)

    'propString=AddedObjectList(CurrentObject)
    'sub SetFIELD(Source$,delim$,fnum%,updField$)
    'sHnd$=str$(BoxTab(ObjTIdx).Handle)
    'SetFIELD(@propString,"|",3, sHnd$ )
    'AddedObjectList(CurrentObject)=propString

    TabCtrl(ObjTIdx).TabInactiveFont=StrFont(CurrentObject)
    TabCtrl(ObjTIdx).TabIndex=GetPropValue ("TabIndex")
    TabCtrl(ObjTIdx).TabPosition=GetPropValue ("TabPosition")
    TabCtrl(ObjTIdx).TabWidth=GetPropValue ("TabWidth")
    TabCtrl(ObjTIdx).VerticalTabs=GetPropValue ("VerticalTabs")

    'redraw
    'BoxTab(ObjTIdx).visible=false
    BoxTab(ObjTIdx).visible=true
    TabCtrl(ObjTIdx).visible=false
    TabCtrl(ObjTIdx).visible=true'



  CASE Q_COMBOBOX      '11
    ' Combo(ComboIndex+1)

    Combo(ObjTIdx).color=GetPropValue ("color")
    Combo(ObjTIdx).align=GetPropValue ("align")
    Combo(ObjTIdx).cursor=GetPropValue ("cursor")
    Combo(ObjTIdx).showhint=GetPropValue ("showhint")
    Combo(ObjTIdx).hint=GetPropString("hint")
    'Combo(ObjTIdx).enabled=GetPropValue("enabled")

    Combo(ObjTIdx).DropDownCount=GetPropValue("DropDownCount")
    Combo(ObjTIdx).CopyMode=GetPropValue("CopyMode")
    Combo(ObjTIdx).ItemHeight=GetPropValue("ItemHeight")
    Combo(ObjTIdx).ItemIndex=GetPropValue("ItemIndex")
    Combo(ObjTIdx).MaxLength=GetPropValue("MaxLength")
    Combo(ObjTIdx).Sorted=GetPropValue("Sorted")
    Combo(ObjTIdx).Style=GetPropValue("Style")
    Combo(ObjTIdx).Text=GetPropString("Text")

    'redraw
    Combo(ObjTIdx).visible=false
    Combo(ObjTIdx).visible=true'


  CASE Q_LISTBOX       '12
    'ListB(ListBIndex+1) AS QLISTBOX
    ListB(ObjTIdx).color=GetPropValue ("color")
    ListB(ObjTIdx).align=GetPropValue ("align")
    ListB(ObjTIdx).cursor=GetPropValue ("cursor")
    ListB(ObjTIdx).showhint=GetPropValue ("showhint")
    ListB(ObjTIdx).hint=GetPropString("hint")
    ListB(ObjTIdx).Sorted=GetPropValue("Sorted")
    ListB(ObjTIdx).Style=GetPropValue("Style")
    ListB(ObjTIdx).Text=GetPropString("Text")
    ListB(ObjTIdx).Columns=GetPropValue ("Columns")
    ListB(ObjTIdx).CopyMode=GetPropValue ("CopyMode")
    ListB(ObjTIdx).ExtendedSelect=GetPropValue ("ExtendedSelect")
    ListB(ObjTIdx).ItemHeight=GetPropValue ("ItemHeight")
    ListB(ObjTIdx).ItemIndex=GetPropValue ("ItemIndex")
    ListB(ObjTIdx).MultiSelect=GetPropValue ("MultiSelect")
    ListB(ObjTIdx).Sorted=GetPropValue ("Sorted")
    ListB(ObjTIdx).Style=GetPropValue ("Style")
    ListB(ObjTIdx).TabWidth=GetPropValue ("TabWidth")
    ListB(ObjTIdx).TopIndex=GetPropValue ("TopIndex")

    ListB(ObjTIdx).borderstyle=GetPropValue ("borderstyle")
    propString=AddedObjectList(CurrentObject)
    'sub SetFIELD(Source$,delim$,fnum%,updField$)
    sHnd$=str$(ListB(ObjTIdx).Handle)
    SetFIELD(@propString,"|",3, sHnd$ )
    AddedObjectList(CurrentObject)=propString

    'redraw
    ListB(ObjTIdx).visible=false
    ListB(ObjTIdx).visible=true'



  CASE Q_GROUPBOX      '13
    'GrpBox(GrpBoxIndex+1) AS QGROUPBOX


    GrpBox(ObjTIdx).align=GetPropValue ("align")
    GrpBox(ObjTIdx).caption=GetPropString ("caption")' BevelOuter
    GrpBox(ObjTIdx).color=GetPropValue ("color")
    GrpBox(ObjTIdx).cursor=GetPropValue ("cursor")
    GrpBox(ObjTIdx).showhint=GetPropValue ("showhint")
    GrpBox(ObjTIdx).hint=GetPropString("hint")
    GrpBox(ObjTIdx).Font=StrFont(CurrentObject)

    'redraw
    GrpBox(ObjTIdx).visible=false
    GrpBox(ObjTIdx).visible=true'


  CASE Q_SCROLLBOX     '14
    'reDIM ScrollB(ScrollBIndex+1) AS QSCROLLBOX
    'reDIM BoxInner(ScrollBIndex+1) AS QPANEL                              ' For effect - force scrollbars visible

    ScrollB(ObjTIdx).align=GetPropValue ("align")
    ScrollB(ObjTIdx).color=GetPropValue ("color")
    ScrollB(ObjTIdx).cursor=GetPropValue ("cursor")
    ScrollB(ObjTIdx).showhint=GetPropValue ("showhint")
    ScrollB(ObjTIdx).hint=GetPropString("hint")
    ScrollB(ObjTIdx).Font=StrFont(CurrentObject)

    ScrollB(ObjTIdx).AutoScroll=GetPropValue ("AutoScroll")
    ScrollB(ObjTIdx).HorzMargin=GetPropValue ("HorzMargin")' BevelOuter
    ScrollB(ObjTIdx).HorzPosition=GetPropValue ("HorzPosition")
    ScrollB(ObjTIdx).HorzTracking=GetPropValue ("HorzTracking")
    ScrollB(ObjTIdx).HorzVisible=GetPropValue ("HorzVisible")
    ScrollB(ObjTIdx).VertIncrement=GetPropValue("VertIncrement")

    ScrollB(ObjTIdx).VertMargin=GetPropValue ("VertMargin")
    ScrollB(ObjTIdx).VertPosition=GetPropValue ("VertPosition")
    ScrollB(ObjTIdx).VertRange=GetPropValue ("VertRange")
    ScrollB(ObjTIdx).VertTracking=GetPropValue ("VertTracking")
    ScrollB(ObjTIdx).VertVisible=GetPropValue("VertVisible") '!!! не работает

    'ScrollB(ObjTIdx).BorderStyle=GetPropValue("BorderStyle")

    brem 0
    propString=AddedObjectList(CurrentObject)
    'sub SetFIELD(Source$,delim$,fnum%,updField$)
    sHnd$=str$(ScrollB(ObjTIdx).Handle)
    SetFIELD(@propString,"|",3, sHnd$ )
    AddedObjectList(CurrentObject)=propString
    erem

    'redraw
    ScrollB(ObjTIdx).visible=false
    ScrollB(ObjTIdx).visible=true'



  CASE Q_SCROLLBAR     '15

    'reDIM ScrollBar(ScrllBarIndex+1) AS QSCROLLBAR

    ScrollBar(ObjTIdx).align=GetPropValue ("align")
    ScrollBar(ObjTIdx).kind=GetPropValue ("kind")
    ScrollBar(ObjTIdx).cursor=GetPropValue ("cursor")
    ScrollBar(ObjTIdx).showhint=GetPropValue ("showhint")
    ScrollBar(ObjTIdx).hint=GetPropString("hint")

    'ScrollBar(ObjTIdx).top=GetPropValue ("top")
    'ScrollBar(ObjTIdx).left=GetPropValue ("left")
    'ScrollBar(ObjTIdx).height=GetPropValue ("height")
    'ScrollBar(ObjTIdx).width=GetPropValue ("width")

    'PageSize
    'Position


  CASE Q_STRINGGRID    '16
  CASE Q_LISTVIEW      '17
  CASE Q_DIRTREE       '18
  CASE Q_FILELISTBOX   '19
  CASE Q_TREEVIEW      '20
  CASE Q_OUTLINE       '21
  CASE Q_GAUGE         '22
  CASE Q_TRACKBAR      '23
  CASE Q_HEADER        '24
  CASE Q_STATUSBAR     '25
  CASE Q_CANVAS        '26
  CASE Q_IMAGE         '27
  CASE Q_OLECONTAINER  '28
  CASE Q_SPLITTER      '29

  end select
  '!!! BuildFormCode

end sub

'!!*****************************************
SUB ReDrawComponent

  exit sub '!!!<<<<<<<<<<


  DEFSTR propString, token, tstr, cap
  DEFINT i, X, Y, Height, Width, objType, reposn,ObjTIdx
  DEFLNG hWnd, parenthWnd
  DIM rect AS QRECT
  DIM ParentRect AS QRECT

  defint rowi, ci
  defstr celli
  defstr const_i


  propString=AddedObjectList(CurrentObject)
  call  AddClrString ("1864:ReDrawComponent CurrentObject="+str$(CurrentObject), clGrey, LogEdit)
  'call  AddClrString ("1791:propString="+(propString), clb, LogEdit)
  tstr=FIELD$(propString,"~",1)
  call  AddClrString ("2818:tstr="+str$(tstr), clred, LogEdit)
  objType=VAL(FIELD$(tstr,"|",1))
  call  AddClrString ("2820:objType="+str$(objType), clred, LogEdit)
  IF objType>=NON_VISIBLE THEN EXIT SUB

  reposn=False
  hWnd=VAL(FIELD$(tstr,"|",3))

  'parenthWnd=GetParent(hWnd)
  'call  AddClrString ("2842:parenthWnd="+str$(parenthWnd), clred, LogEdit)
  'if parenthWnd>0 then
  'GetWindowRect(parenthWnd,ParentRect)
  'else
  'call  AddClrString ("2842:No parent !!! parenthWnd="+str$(parenthWnd), clred, LogEdit)

  'end if

  FOR i=2 TO TALLY(propString,"~")
    tstr=FIELD$(propString,"~",i)
    'call  AddClrString ("1800:tstr="+(tstr), cldg, LogEdit)
    token=UCASE$(FIELD$(tstr,"|",1))
    'call  AddClrString ("---- 1802:ReDrawComponent token="+(token), clGrey, LogEdit)

    'Width=Screen.Width
    'Height=GetScreenHeight()
    'MainForm.ClientWidth\2
    'Left=450+6*30
    'Width=Screen.Width*3\4
    'Height=MainForm.ClientHeight-ToolBox.Height-stat.Height
    'Width=DesignPan.ClientWidth
    'Height=DesignPan.ClientHeight
    'Align=alClient
    'Width=ComponentPan.ClientWidth-4




    SELECT CASE token
    CASE "LEFT": X=VAL(FIELD$(tstr,"|",4)): reposn=True
      if x<0 then x=0
    CASE "TOP": Y=VAL(FIELD$(tstr,"|",4)): reposn=True
      if y<0 then y=0

    CASE "WIDTH":
      Width=VAL(FIELD$(tstr,"|",4)): reposn=True
      if width<1 then width=Screen.Width/1.5
      call  AddClrString ("2857:Width="+str$(Width), clm, LogEdit)

    CASE "HEIGHT":
      Height=VAL(FIELD$(tstr,"|",4)): reposn=True
      if Height<1 then Height=Screen.Height/1.5
      call  AddClrString ("2861:Height="+str$(Height), clm, LogEdit)

    CASE "CAPTION", "TEXT"
      cap=FIELD$(tstr,"|",4)
      SetWindowText(hWnd,cap)                             ' Update object text
      IF objType=Q_GROUPBOX THEN
        SetWindowPos(hWnd,0,0,0,0,0,SWP_FLAGS)          ' Fudge to fix QGroupbox only!
      END IF
    case "COLOR":
      ' Forms(CurrentForm).color=ColorPick.Color

    END SELECT
  NEXT i

  IF objType=Q_OVALBTN THEN                                       ' Handle QOvalBtn differently
    tstr=FIELD$(propString,"~",1)
    i=VAL(FIELD$(tstr,"|",7))                                   ' Array index of the ovalbtn
    OvalRepaint(i,X,Y,Width,Height,cap)
  ELSEIF reposn THEN
    HideCarets                                                  ' If visible
    SetWindowPos(hWnd, 0, X, Y, Width, Height, SW_FLAGS)
    IF objType>0 THEN                                           ' If NOT a form
      GetWindowRect(hWnd,rect)
      ShowCarets(rect)
    END IF
  END IF

  '!!! BuildFormCode
END SUB

' FIXME:
'*****************************************
SUB SetPropertyColor(colour AS long)
  DEFLNG hWnd, hbr
  DEFSTR tstr
  DIM rct AS QRECT
  '
  '    tstr=FIELD$(AddedObjectList(CurrentObject),"~",1)
  '    hWnd=VAL(FIELD$(tstr,"|",3))
  '    GetClientRect(hWnd, rct)
  '    hbr=CreateSolidBrush(colour)
  '    DeleteObject(SetClassLong(hWnd, -10, hbr))                 ' GCL_HBRBACKGROUND = -10
  '    InvalidateRect(hWnd, rct, TRUE)
END SUB


'*****************************************
' Edit a property field using the combobox
SUB FieldUpdateCombo(Sender) '!!!! <<< необновленные процедуры
  'call  AddClrString ("6201:FieldUpdateCombo="+str$(FieldUpdateCombo), 444, LogEdit)
  DEFSTR tstr, tok
  DEFINT i, Row, ColorChosen=False

  Row=Sender.Tag

  ' The saved Row we are editing
  'call  AddClrString ("6206:Row="+str$(Row), clred, LogEdit)
  tstr=Sender.Item(Sender.ItemIndex)                              ' The combobox selection
  'call  AddClrString ("-------- 6236:tstr="+(tstr), 0, LogEdit)

  PropertyGrid.Cell(1,Row)=tstr
  OldPv$=tstr
  'call  AddClrString ("6315:OldPv$="+(OldPv$), clred, LogEdit)


  IF UCASE$(tstr)="<CHOOSE COLOR>" THEN                                 ' A change!
    tok=PropertyGrid.Cell(0,Row)+" ["
    'call  AddClrString ("6240:tok="+(tok), 555, LogEdit)

    'tok=tok+FIELD$(SelectionCombo.Item(SelectionCombo.ItemIndex),"[",1)+"]" '!! &&&&&&&&&&&&&&&&

    'call  AddClrString ("6241:tok="+(tok), 0, LogEdit)
    ColorPick.Caption=tok                                       ' Prepare the caption for color chooser
    tok=PropertyGrid.Cell(1,Row)                                ' Last value for color
    'call  AddClrString ("6244:tok="+(tok), clred, LogEdit)
    IF LEFT$(tok,2)="&H" THEN                                   ' Colour has been set before?
      'call  AddClrString ("6249:tok="+(tok), clred, LogEdit)
      'ColorPick.Color=VAL(CONVBASE$(tok,16,10))               ' Change "default" colour
      'call  AddClrString ("6250:ColorPick.Color="+str$(ColorPick.Color), 333, LogEdit)
      '       ELSE
      '          Uses the LAST set "default" colour!!!
    END IF
    IF ColorPick.Execute THEN
      tstr="&H"+RIGHT$(HEX$(ColorPick.Color),6)               ' Updated value
      'call  AddClrString ("2590:ColorPick tstr="+(tstr), 6666, LogEdit)
      'tstr="&H"+RIGHT$(HEX$(ColorDialog.RgbColor),6)
      ColorChosen=True
      PropertyGrid.Cell(1,Row)=tstr
      Sender.AddItems tstr
      Sender.ItemIndex=Sender.ItemCount-1

      OldPv$=tstr
      'call  AddClrString ("6344:OldPv$="+(OldPv$), clred, LogEdit)
    ELSE
      tstr=PropertyGrid.Cell(1,Row)                           ' NO change!
    END IF
  END IF

  IF UCASE$(tstr)="<CHOOSE FONT>" THEN                                 ' A change!


    if PropertyGrid.Cell(2,Row)<>"" then
      FontDialog.GetFont(StrFont(CurrentObject))
    end if

    IF FontDialog.Execute THEN
      'FontDialog.SetFont(Font)
      'FontLbl.Font.Name=FontDialog.Name
      'FontLbl.Font.Size=FontDialog.Size
      FontDialog.SetFont(StrFont(CurrentObject))
      PropertyGrid.Cell(2,Row)=StrFont(CurrentObject).Name+" Size="+str$(StrFont(CurrentObject).Size)+" bold="+str$(StrFont(CurrentObject).bold)

      'MarginEdit.SelAttributes=StrFont
      'FontLbl.Font=StrFont
      'SrcEdit.Font.Name=FontDialog.Name
      'SrcEdit.Font.Size=FontDialog.Size


    END IF


  END IF



  IF tstr<>PropertyGrid.Cell(1,Row) THEN                          ' Changed?
    PropertyGrid.Cell(1,Row)=tstr
    'PropertyFieldUpdate(PropertyGrid.Cell(0,Row),tstr,4)        ' print New current value in PropertyGrid
    PropertyFieldUpdate(PropertyGrid.Cell(0,Row),tstr)        ' print New current value in PropertyGrid
    IF ColorChosen THEN
      'PropertyFieldUpdate(PropertyGrid.Cell(0,Row),tstr,7)    ' New color choice
      PropertyFieldUpdate(PropertyGrid.Cell(0,Row),tstr)    ' New color choice
      'SetPropertyColor(ColorPick.Color)
    END IF
  END IF

  'Sender.Tag=-1                                                   ' Clear saved data

  'Sender.Visible=False
  PropertyValueUpdate
  ReDrawComponentbyField '!!! --------------
  'call  AddClrString ("6244:ReDrawComponentbyField="+str$(ReDrawComponentbyField), 0, LogEdit)
END SUB

'*****************************************
' Return the parameters of the event sub
FUNCTION GetSubParms(pField AS string) AS string'!!!! <<< необновленные процедуры
  DEFSTR tstr, token
  DEFINT i

  Result=""
  tstr=AddedObjectList(CurrentObject)
  FOR i=1 TO TALLY(tstr,"~")
    token=FIELD$(tstr,"~",i)
    IF FIELD$(token,"|",1)=pField THEN
      Result=FIELD$(token,"|",3)
      EXIT FOR
    END IF
  NEXT i
END FUNCTION

'*****************************************
' Edit a property/method/event field using the edit box
SUB FieldUpdateEdit(Key,Shift,Sender) '!!!! <<<<< необновленные процедуры
  call  AddClrString ("2862:FieldUpdateEdit="+str$(FieldUpdateEdit), 6666, LogEdit)
  DEFSTR oldStr, newStr, pField, token
  DEFINT Row

  IF Key=13 THEN                                                  ' Finished editing this field?
    Row=Sender.Tag                                              ' The saved Row we are editing
    Sender.Tag=-1
    newStr=LTRIM$(RTRIM$(Sender.Text))
    SELECT CASE ObjInspectorTab.TabIndex
    CASE 0: oldStr=PropertyGrid.Cell(1,Row)
    CASE 1: oldStr=MethodGrid.Cell(1,Row)
    CASE 2: oldStr=EventGrid.Cell(1,Row)
    END SELECT

    IF oldStr=newStr THEN                                       ' No change?
      'Sender.Visible=False
      EXIT SUB
    END IF

    SELECT CASE ObjInspectorTab.TabIndex
    CASE 0                                                  ' Component PROPERTY update
      PropertyGrid.Cell(1,Row)=newStr                     ' Update the property grid
      pField=PropertyGrid.Cell(0,Row)
      'PropertyFieldUpdate(pField,newStr,4)                ' Update the global object string
      PropertyFieldUpdate(pField,newStr)                ' Update the global object string
      'call  AddClrString ("1934:pField="+(pField), clm, LogEdit)
      SELECT CASE UCASE$(pField)
      CASE "LEFT","TOP","WIDTH","HEIGHT"',"CAPTION","TEXT","COLOR"
        ReDrawComponent
      END SELECT
    CASE 1                                                  ' Component METHOD update
      MethodGrid.Cell(1,Row)=newStr                       ' Update the property grid
      pField=MethodGrid.Cell(0,Row)
      PropertyFieldUpdate(pField,newStr) ',4                ' Update the global object string
      MethodUpdate(newStr)
    CASE 2                                                  ' Component EVENT update
      EventGrid.Cell(1,Row)=newStr                        ' Update the event grid
      pField=EventGrid.Cell(0,Row)
      PropertyFieldUpdate(pField,newStr)',2                ' Update the global object string
      IF newStr="" THEN                                   ' Cleared an event?
        oldStr="SUB "+oldStr
        IF INSTR(FwdDeclares,oldStr)<>0 THEN            ' Old SUB exists in our CURRENT declares?
          oldStr=oldStr+GetSubParms(pField)+"~"       ' Get parameters of this sub
          FwdDeclares=FwdDeclares-oldStr              ' Remove the forward declaration...
        END IF                                          ' ..NB NOT from the entire users code!
      ELSE
        newStr="SUB "+newStr
        IF INSTR(FwdDeclares,newStr)=0 THEN             ' New SUB doesn't exist?
          newStr=newStr+GetSubParms(pField)+"~"       ' Get parameters of this sub
          FwdDeclares=FwdDeclares+newStr              ' Add the forward declaration
        END IF
      END IF
    END SELECT

    'Sender.Visible=False
    PropertyValueUpdate
    ReDrawComponentbyField ' !!! <<<<<<<<<<<<<<<<<<<<<<<
    'call  AddClrString ("6321:ReDrawComponentbyField="+str$(ReDrawComponentbyField), 0, LogEdit)
    oldr=PropertyGrid.Row
    PropertyGrid.Row=-1
    PropertyGrid.Repaint
    'PropertyGrid.Row=oldr
    'PropertyGrid.Repaint
    'Sender.Visible=False

    '!ReDrawComponent
    'PropertyGrid.Row=Row
    'ReDrawComponent
  elseif Key=27 then

    PropertyGrid.Cell(PropertyGrid.Col,PropertyGrid.Row)=OldPv$ '!восстанавливаем предыдущее значение!!
    Sender.Text=OldPv$
    'call  AddClrString ("14687:OldPv$="+(OldPv$), clred, LogEdit)

  else
    OldPv$=FieldEdit.Text
    'call  AddClrString ("6373:--- OldPv$="+(OldPv$), cldb, LogEdit)

  END IF


END SUB

'*****************************************
' User selected a field in the property string grid
SUB EditPropertyField(Col, Row, CanSelect, Sender)'!!!!
  call  AddClrString ("6381:EditPropertyField Row="+str$(Row), clb, LogEdit)
  DEFINT i, top, cnt, Sel
  DEFSTR tstr, tok

  'сохраняем изменения предыдущего свойства.
  'OldPv$="" ' старое значение свойства
  'defint OldCol=-1,OldRow=-1 ' предыдущая ячейка. При клике на новую ячейку значение из edit переписывается в ячейку

  'call  AddClrString ("6390:OldRow="+str$(OldRow), clred, LogEdit)
  FieldEdit.Visible=False                                         ' Ensure the field QEDIT hidden
  FieldBox.Visible=False                                          ' Ensure the field QCOMBOBOX hidden
  'ObjectHandle(ObjectIndex)
  'call  AddClrString ("6493:ObjectIndex="+str$(ObjectIndex), clred, LogEdit)
  'call  AddClrString ("6493:EditPropertyField ObjectHandle("+str$(ObjectIndex)+")="+str$(ObjectHandle(ObjectIndex)), cldg, LogEdit)

  'call  AddClrString ("6528:EditPropertyField OldRow="+str$(OldRow), cldb, LogEdit)


  if col>1 then
    FieldEdit.Visible=False                                         ' Ensure the field QEDIT hidden
    FieldBox.Visible=False                                          ' Ensure the field QCOMBOBOX hidden
    exit sub
  end if

  if OldRow>-1 then
    PropertyGrid.Cell(OldCol,OldRow)=OldPv$
    'call  AddClrString ("6393:OldPv$="+(OldPv$), clred, LogEdit)
  end if


  OldPv$=PropertyGrid.Cell(Col,Row) '!сохраняем текущее  значение ячейки!!
  'call  AddClrString ("6377:EditPropertyField OldPv$="+(OldPv$), clo, LogEdit)

  OldCol=Col
  'call  AddClrString ("6401:OldCol="+str$(OldCol), clred, LogEdit)
  OldRow=Row ' сохраняем параметры ячейки
  'call  AddClrString ("6403:OldRow="+str$(OldRow), clred, LogEdit)

  HideCarets                                                      ' Ensure hidden
  FieldEdit.Visible=False                                         ' Ensure the field QEDIT hidden
  FieldBox.Visible=False                                          ' Ensure the field QCOMBOBOX hidden

  'tstr=AddedObjectList(CurrentObject)
  otype$=ObjectType(ObjectIndex) ' FIELD$(tstr,"|",2)
  'call  AddClrString ("2724:otype="+(otype$), clred, LogEdit)


  'tstr=FIELD$(tstr,"~",Row+1)                                     ' Get the property string we are editing
  tstr=DefaultPropertyGrid.cell(1,Row-1)
  'call  AddClrString ("6392:tstr="+(tstr), 777, LogEdit)

  '!IF FIELD$(tstr,"|",3)="R" THEN EXIT SUB                         '!!! If property is read only then Exit

  if tstr="R" THEN EXIT SUB                '!!! If property is read only then Exit

  pn$=Sender.cell(0,Row) ' property name
  'call  AddClrString ("6398:pn$="+(pn$), clp, LogEdit)

  pv$=Sender.cell(1,Row) ' property value
  'call  AddClrString ("6381:pv$="+(pv$), clp, LogEdit)

  tstr=Sender.cell(1,Row)
  'call  AddClrString ("2723:tstr="+(tstr), clp, LogEdit)



  h=Sender.DefaultRowHeight+1                         ' Height + gridline
  'call  AddClrString ("2730:h="+str$(h), clb, LogEdit)
  top=h*(Row-Sender.TopRow+1)+Sender.Top '+(h\2)  ' Adjusted for scroll & TABs height (1.5 * i)


  tstr=DefaultPropertyGrid.cell(3,Row-1)
  'call  AddClrString ("6414:tstr="+(tstr), 0, LogEdit)
  cnt=TALLY(tstr,"|")
  'call  AddClrString ("6415:cnt="+str$(cnt), clred, LogEdit)

  FieldBox.Width=Sender.ColWidths(0)+1        ' Number items this property
  FieldEdit.Width=Sender.ColWidths(0)+1       ' Number items this property

  IF cnt>0 THEN                               ' Multi-choice? Use the field COMBOBOX
    FieldBox.Top=top                          ' Position over correct cell
    FieldBox.Clear: Sel=0

    FOR i=1 TO cnt+1
      tok=FIELD$(tstr,"|",i)                  ' Add each possible value to the list
      FieldBox.AddItems tok
      IF tok=Sender.Cell(1,Row) THEN Sel=i-1  ' CURRENT value? Save its index
    NEXT i

    tstr=Sender.Cell(1,Row)
    'call  AddClrString ("6423:tstr="+str$(tstr), clred, LogEdit)

    IF (LEFT$(tstr,1) <> "<") AND (LEFT$(FieldBox.Item(0),1)="<") THEN      ' Color?
      FieldBox.AddItems tstr                                  ' Previous color selected? Add it to list
      FieldBox.ItemIndex=i '-5                                  ' Now select it!
    ELSE
      FieldBox.ItemIndex=Sel                                  ' Select CURRENT value from the list
    END IF

    FieldBox.Tag=Row                                            ' Save Row for updating correct field
    FieldBox.Visible=True
  ELSE                                                            ' Single field use the field EDIT BOX
    FieldEdit.Top=top
    FieldEdit.Text=pv$ 'FIELD$(tstr,"|",1)
    FieldEdit.Tag=Row                                           ' Save Row for updating correct field
    FieldEdit.Visible=True
    SetFocus(FieldEdit.Handle)
  END IF

  if otype$="QRICHEDIT" then
    'ObjTIdx=ObjTypeIndex(CurrentObject)
    'call  AddClrString ("2751:ObjTIdx="+str$(ObjTIdx), clred, LogEdit)
    'tmpRichEdit.parent=BoxRICH(ObjTIdx)
    'tmpRichEdit.align=alclient
    'tmpRichEdit.borderstyle=bsnone
    'tmpRichEdit.color=clwhite'BoxRICH(ObjTIdx).color
  end if

  'exit sub '!!<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<!'
  ReDrawComponentbyField '!!! <<<<<<<<<<<<<<<<<<<<<<<<
  'call  AddClrString ("6388:ReDrawComponentbyField="+str$(ReDrawComponentbyField), 0, LogEdit)

  'rr=row
  'call  AddClrString ("6446:rr="+str$(rr), cldp, LogEdit)

  Sender.Repaint

END SUB

'*****************************************
' User selected a field in the method string grid
SUB EditMethodField(Col, Row, CanSelect, Sender)'!!!! <<< необновленные процедуры
  DEFINT i, top, cnt
  DEFSTR objString, tstr, token

  HideCarets                                                      ' Ensure hidden
  'FieldEdit.Visible=False                                         ' Likewise
  'FieldBox.Visible=False                                          ' ditto

  token=Sender.Cell(0,Row)                                        ' The method name
  objString=AddedObjectList(CurrentObject)
  'call  AddClrString ("2002:objString="+str$(objString), clred, LogEdit)
  cnt=TALLY(objString,"~")                                        ' Number of lines this component
  FOR i=2 TO cnt
    tstr=FIELD$(objString,"~",i)                                ' Find the method fields
    IF LEFT$(tstr,1)="*" THEN EXIT FOR
  NEXT i
  FOR i=i TO cnt
    tstr=FIELD$(objString,"~",i)                                ' Find this method
    IF token=FIELD$(tstr,"|",1) THEN EXIT FOR
  NEXT i
  IF FIELD$(tstr,"|",3)<>"W" THEN EXIT SUB                        ' NOT writable then exit

  token=FIELD$(tstr,"|",4)                                        ' Get the value
  i=Sender.DefaultRowHeight+1                                     ' Height + gridline
  top=i*(Row-Sender.TopRow+2)+(i\2)                               ' Adjusted for scroll & TABs height
  FieldEdit.Top=top
  FieldEdit.Text=token
  FieldEdit.Tag=Row                                               ' Save Row for updating correct field
  FieldEdit.Visible=True
  SetFocus(FieldEdit.Handle)
END SUB

'*****************************************
' User selected a field in the event string grid
SUB EditEventField(Col, Row, CanSelect, Sender)'!!!! <<< необновленные процедуры
  DEFINT i, j, top, cnt
  DEFSTR objString, tstr, token

  HideCarets                                                      ' Ensure hidden
  'FieldEdit.Visible=False                                         ' Likewise
  'FieldBox.Visible=False                                          ' ditto

  token=Sender.Cell(0,Row)                                        ' The event name
  objString=AddedObjectList(CurrentObject)
  cnt=TALLY(objString,"~")                                        ' Number of lines this component
  j=0
  FOR i=2 TO cnt
    tstr=FIELD$(objString,"~",i)                                ' Find the event fields
    IF LEFT$(tstr,1)="*" THEN INC j
    IF j=2 THEN EXIT FOR
  NEXT i
  FOR i=i TO cnt
    tstr=FIELD$(objString,"~",i)                                ' Find this event
    IF token=FIELD$(tstr,"|",1) THEN EXIT FOR
  NEXT i
  token=FIELD$(tstr,"|",2)                                        ' Get the value

  i=Sender.DefaultRowHeight+1                                     ' Height + gridline
  top=i*(Row-Sender.TopRow+2)+(i\2)                               ' Adjusted for scroll & TABs height
  FieldEdit.Top=top
  FieldEdit.Text=token
  FieldEdit.Tag=Row                                               ' Save Row for updating correct field
  FieldEdit.Visible=True
  SetFocus(FieldEdit.Handle)
END SUB

'*****************************************
' Tag property tracks the TopRow so if user "scrolls" component data (Properties)
' then the "Field boxes" are cleared. eg QRichEdit, QTabControl & QStringGrid
SUB HideEditCtls(Col,Row,State,Rect,Sender)
  IF Sender.Tag<>Sender.TopRow THEN                               ' Have we scrolled?
    'FieldEdit.Visible=False                                     ' Ensure this hidden
    'FieldBox.Visible=False                                      ' ditto
    Sender.Tag=Sender.TopRow                                    ' Update copy of TopRow
  END IF
END SUB


'----------------------- Displaying code in the TextCode Screen -----------------------------------
' Entry point: BuildFormCode()
'
'*****************************************
SUB InsertCodeHeader  '!!!! <<< необновленные процедуры                                              ' STAND_ALONE mode only
  DEFINT i
  DEFSTR tstr

  CodeText.AddStrings "'", "' <Program Name>", "'"                ' Add a default header
  '    CodeText.AddStrings "' RapidFRM "+VER,"'",""
  CodeText.AddStrings "'$APPTYPE GUI", "$TYPECHECK ON",""
  CodeText.AddStrings "$INCLUDE <Rapidq2.inc>", ""

  FwdDeclares=LTRIM$(FwdDeclares)

  IF FwdDeclares<>"" THEN                                         ' Add any Forward declarations
    FOR i=1 TO TALLY(FwdDeclares,"~")
      tstr=LTRIM$(RTRIM$(FIELD$(FwdDeclares,"~",i)))
      CodeText.AddStrings "DECLARE "+tstr
    NEXT i
    CodeText.AddStrings ""
  END IF
END SUB

'*****************************************
SUB InsertCodeFooter     '!!!! <<< необновленные процедуры                                           ' STAND_ALONE mode only
  DEFINT i
  DEFSTR tstr

  tstr=FIELD$(AddedObjectList(0),"~",1)                                ' Initial form
  tstr=FIELD$(tstr,"|",4)                                         ' The form name
  CodeText.AddStrings "SetWindowLong("+tstr+".Handle, GWL_HWNDPARENT, 0)"
  CodeText.AddStrings "SetWindowLong(Application.Handle, GWL_HWNDPARENT, "+tstr+".Handle)",""
  CodeText.AddStrings tstr+".ShowModal",""
  IF FwdDeclares<>"" THEN                                         ' Add the FwdDEclare sub templates
    FOR i=1 TO TALLY(FwdDeclares,"~")
      tstr=LTRIM$(RTRIM$(FIELD$(FwdDeclares,"~",i)))
      CodeText.AddStrings tstr,"END SUB"
      CodeText.AddStrings
    NEXT i
  END IF
END SUB

'*****************************************
SUB InsertNonVisible'!!!! <<< необновленные процедуры
  DEFINT i, k, cnt, objID
  DEFSTR defString, nuString, tstr, token
  DEFSTR spacer=SPACE$(4)

  FOR i=1 TO MAX_OBJECTS                                          ' Loop through the AddedObjectList...
    nuString=AddedObjectList(i)                                      ' ..for non-visible objects
    IF nuString="" THEN EXIT FOR                                ' End of object list so exit
    tstr=FIELD$(nuString,"~",1)                                 ' First line of object string
    objID=VAL(FIELD$(tstr,"|",1))
    IF objID >= NON_VISIBLE THEN                                ' Interested?
      IF ProjectMode=STAND_ALONE THEN
        token=FIELD$(tstr,"|",4)                            ' Internal object name
      ELSE
        token=FIELD$(tstr,"|",5)                            ' Project object name
      END IF
      tstr="DIM "+token+" AS "+FIELD$(tstr,"|",2)
      CodeText.AddStrings tstr
      defString="Dummy align string~"                         ' Add this to align with AddedObjectList() string
      defString=defString+GetDefaultProperties(objID)         ' Default properties this object type
      cnt=TALLY(defString,"~")                                ' Num properties this object
      FOR k=2 TO cnt
        tstr=FIELD$(nuString,"~",k)                         ' Loop through each current prop line
        IF FIELD$(defString,"~",k)<>tstr THEN               ' Equal default property line?
          IF UCASE$(LEFT$(tstr,2))="ON" THEN              ' An event?
            CodeText.AddStrings spacer+token+"."+FIELD$(tstr,"|",1) _
            +" = "+FIELD$(tstr,"|",2)
          ELSE                                            ' A property!
            SELECT CASE FIELD$(tstr,"|",1)              ' No, so include the change
            CASE "Parent"                           ' Don't include this!
            CASE ELSE
              IF FIELD$(tstr,"|",2)="STRING" THEN
                CodeText.AddStrings spacer+token+"."+FIELD$(tstr,"|",1) _
                +" = "+QU+FIELD$(tstr,"|",4)+QU
              ELSE
                CodeText.AddStrings spacer+token+"."+FIELD$(tstr,"|",1)+" = "+FIELD$(tstr,"|",4)
              END IF
            END SELECT
          END IF
        END IF
      NEXT k
      CodeText.AddStrings ""
    END IF
  NEXT i
END SUB

'*****************************************
' Insert code for QMainMenus and/or QPopupMenus with formatting
SUB InsertMenu(which AS integer)'!!!! <<< необновленные процедуры
  DEFINT i, j, cnt, lev
  DEFSTR mnuString, tstr, token, spacer

  IF which=MAINMENU THEN mnuString=LTRIM$(MainMenuList) ELSE mnuString=LTRIM$(PopMenuList)
  cnt=TALLY(mnuString,"@")
  FOR i=1 TO cnt
    lev=0: spacer=""
    tstr=FIELD$(mnuString,"@",i)+"~"                            ' Each menu block
    FOR j=1 TO TALLY(tstr,"~")
      token=FIELD$(tstr,"~",j)                                ' Each menu line
      IF LEFT$(LTRIM$(token),1)="'" THEN
        CodeText.AddStrings token
      ELSE
        IF INSTR(token,"=")>0 THEN
          token=RTRIM$(FIELD$(token,"=",1))+" = "+LTRIM$(FIELD$(token,"=",2))
        END IF
        IF INSTR(UCASE$(token),"CAPTION")>0 THEN
          token=FIELD$(token," ",1)+" = "+QU+LTRIM$(FIELD$(token,"=",2))+QU
        END IF
        IF UCASE$(FIELD$(token," ",1))="END" THEN
          spacer=LEFT$(spacer,LEN(spacer)-4)              ' Dec spacer then add line
          CodeText.AddStrings spacer+token
        ELSEIF UCASE$(FIELD$(token," ",1))="CREATE" THEN
          CodeText.AddStrings spacer+token                ' Add line then inc spacer
          spacer=spacer+"    "
        ELSE
          CodeText.AddStrings spacer+token
        END IF
      END IF
    NEXT j
    CodeText.AddStrings ""
  NEXT i
END SUB

'*****************************************
FUNCTION ObjectHasChildren(ThisIdx AS integer) AS integer'!!!! <<< необновленные процедуры
  DEFINT i
  DEFLNG hWnd
  DEFSTR tstr

  Result=False
  tstr=FIELD$(AddedObjectList(ThisIdx),"~",1)
  hWnd=VAL(FIELD$(tstr,"|",3))                                    ' Handle of (parent) object
  FOR i=ThisIdx+1 TO ObjectIndex-1                                ' Search after this object
    tstr=FIELD$(AddedObjectList(i),"~",1)
    IF hWnd=VAL(FIELD$(tstr,"|",6)) THEN                        ' Found an object with this parent
      Result=True
      EXIT FOR
    END IF
  NEXT i
END FUNCTION


'*****************************************
' FIXME Component "methods" of type OTHER THAN <Array of strings>!!
SUB InsertObjectCode(ThisIdx AS integer, lev AS integer)'!!!! <<< необновленные процедуры
  call  AddClrString ("6791:InsertObjectCode ThisIdx="+str$(ThisIdx), cldp, LogEdit)
  DEFINT i, j, cnt, aligned, addquotes
  DEFSTR tstr, token, defString, nuString, objType$, objName$
  DEFSTR spacer

  spacer=SPACE$(lev*4)
  'nuString=AddedObjectList(ThisIdx)                                    ' This object in the list

  IF ProjectMode=STAND_ALONE THEN
    token=FIELD$(nuString,"|",4)                                ' Internal object name
  ELSE
    token=FIELD$(nuString,"|",5)                                ' Project object name
  END IF

  token=ObjectName(ThisIdx)
  objname$=ObjectName(ThisIdx)
  call  AddClrString ("6809:objname$="+(objname$), clred, LogEdit)
  call  AddClrString ("6775:token========== "+(token), clo, LogEdit)

  objtype$=ObjectType(ThisIdx)
  call  AddClrString ("6812:objtype$="+(objtype$), clred, LogEdit)

  CodeText.AddStrings spacer+"CREATE "+token+" AS "+objtype$ 'FIELD$(nuString,"|",2)
  spacer=spacer+"    "

  'загружаем таблицу свойств

  DefGridFileName$=StartDir+"data\"+objtype$+".data"

  for ri=1 to DefaultPropertyGrid.RowCount-1
    'call  AddClrString ("3573:ri="+str$(ri), clred, LogEdit)
    for cj=0 to DefaultPropertyGrid.ColCount-1
      DefaultPropertyGrid.Cell(cj,ri)=""
    next
  next


  if fileexists (DefGridFileName$)>0 then
    DefaultPropertyGrid.LoadFromFile(DefGridFileName$,0,0,1000)

  else
    'objtype$="qpanel" '"trim$(field$(objtype$," ",1))
    'call  AddClrString ("2101:objtype$="+(objtype$), clb, LogEdit)
    'DefGridFileName$=StartDir+"data\"+objtype$+".data"
    'DefaultPropertyGrid.LoadFromFile(DefGridFileName$,0,0,1000)
    'Showmessage ("7011: File not found "+DefGridFileName$)
  end if


  GridFileName$=projectDir$+"\"+objname$+".dat"
  call  AddClrString ("******** 7005:GridFileName$="+(GridFileName$), clp, LogEdit)
  PropertyGrid.LoadFromFile(GridFileName$,0,0,1000) ' загружаем таблицу свойств для компонента из списка



  '!! Перебираем по таблице свойств и если свойство отлично от дефолтного - добавляем

  for ri=1 to PropertyGrid.RowCount-1
    if PropertyGrid.Cell(0,ri)="" then goto nextri1

    if PropertyGrid.Cell(1,ri)="" or _
    ucase$(PropertyGrid.Cell(0,ri))=ucase$("Parent") or _
    instr(PropertyGrid.Cell(1,ri),"<") or _
    ucase$(PropertyGrid.Cell(0,ri))=ucase$("Handle") then
    'CodeText.AddStrings "'"+PropertyGrid.Cell(0,ri)+"="+PropertyGrid.Cell(1,ri)  '"CREATE "+token+" AS QFORM"
  else

    CodeText.AddStrings spacer+PropertyGrid.Cell(0,ri)+"="+PropertyGrid.Cell(1,ri)  '"CREATE "+token+" AS QFORM"

  end if
  nextri1:
next



goto exitsub6845 '-------------------------------!!



objType=VAL(FIELD$(nuString,"|",1))
defString="Dummy align string~"                                 ' Add this to align with AddedObjectList() string
defString=defString+GetDefaultProperties(objType)               ' Default properties this object type

aligned=False                                                   ' Default Align prop=alNone
cnt=TALLY(defString,"~")
FOR i=2 TO cnt                                                  ' Check for Align=alClient
  tstr=FIELD$(nuString,"~",i)
  IF FIELD$(tstr,"|",1)="Align" THEN
    IF FIELD$(tstr,"|",4)="alClient" THEN
      aligned=True                                        ' Flag it - alClient=True
    END IF
    EXIT FOR
  END IF
NEXT i
addquotes=False

FOR i=2 TO cnt
  tstr=FIELD$(nuString,"~",i)
  IF FIELD$(defString,"~",i)<>tstr THEN
    token=UCASE$(FIELD$(tstr,"|",1))
    IF (LEFT$(token,2)="ON") OR (token="WNDPROC") THEN      ' An event?
      CodeText.AddStrings spacer+FIELD$(tstr,"|",1)+" = "+FIELD$(tstr,"|",2)
    ELSEIF LEFT$(token,3)="ADD" THEN                        ' Add method?
      token=FIELD$(tstr,"|",4)                            ' The values (comma sep strings)
      IF INSTR(token,QU)=0 THEN addquotes=True
      tstr=spacer+FIELD$(tstr,"|",1)+" "
      FOR j=1 TO TALLY(token,",")+1
        IF addquotes THEN tstr=tstr+QU
        tstr=tstr+LTRIM$(RTRIM$(FIELD$(token,",",j)))   ' Add each string
        IF addquotes THEN tstr=tstr+QU
        tstr=tstr+","
      NEXT j
      CodeText.AddStrings LEFT$(tstr,LEN(tstr)-1)         ' Remove trailing ","
    ELSE
      SELECT CASE FIELD$(tstr,"|",1)
      CASE "Parent"                                   ' Don't include this!
      CASE "Width"
        ' Fudge for QSplitter only, but there are more!
        IF aligned=False THEN                       ' If NOT alClient - include this
          CodeText.AddStrings spacer+FIELD$(tstr,"|",1)+" = "+FIELD$(tstr,"|",4)
        END IF
      CASE "Left","Top","Height"
        ' Fudge for QSplitter only, but there are more!
        IF (aligned=False) AND (objType<>Q_SPLITTER) THEN       ' If NOT alClient - include these
          CodeText.AddStrings spacer+FIELD$(tstr,"|",1)+" = "+FIELD$(tstr,"|",4)
        END IF
      CASE "ColWidths"                                ' QStringGrid fudge array of widths
        token=FIELD$(tstr,"|",4)
        FOR j=1 TO TALLY(token,",")+1
          CodeText.AddStrings spacer+FIELD$(tstr,"|",1)+"("+STR$(j-1)+") = "+FIELD$(token,",",j)
        NEXT j
      CASE ELSE
        IF FIELD$(tstr,"|",2)="STRING" THEN         ' This property type a string?
          CodeText.AddStrings spacer+FIELD$(tstr,"|",1)+" = "+QU+FIELD$(tstr,"|",4)+QU
        ELSE
          CodeText.AddStrings spacer+FIELD$(tstr,"|",1)+" = "+FIELD$(tstr,"|",4)
        END IF
      END SELECT
    END IF
  END IF
NEXT i

exitsub6845:


END SUB

'*****************************************
SUB InsertFormCode(idx AS integer)'!!!! <<< необновленные процедуры
  call  AddClrString ("6929:InsertFormCode idx="+str$(idx), cldm, LogEdit)
  '!! idx - ObjectIndex

  DEFINT i, cnt, Maxit
  DEFSTR defString, nuString, tstr, token
  DEFSTR spacer=SPACE$(4)

  Maxit=False                                                     ' Default - forms are not maximised
  'nuString=AddedObjectList(idx)                    ' Get our current object (with changes?)

  'tstr=FIELD$(nuString,"~",1)

  IF ProjectMode=STAND_ALONE THEN
    token=FIELD$(tstr,"|",4)                                    ' Internal object name
  ELSE
    token=FIELD$(tstr,"|",5)                                    ' Project object name
  END IF

  token=ObjectName(idx)
  objname$=ObjectName(idx)
  call  AddClrString ("6954:objname$="+(objname$), clred, LogEdit)
  objtype$=ObjectType(idx)
  call  AddClrString ("6956:objtype$="+(objtype$), clred, LogEdit)

  call  AddClrString ("6857:token="+(token), 8888, LogEdit)

  CodeText.AddStrings "CREATE "+token+" AS QFORM"

  '!! Перебираем по таблице свойств и если свойство отлично от дефолтного - добавляем

  for ri=1 to DefaultPropertyGrid.RowCount-1
    'call  AddClrString ("3573:ri="+str$(ri), clred, LogEdit)
    for cj=0 to DefaultPropertyGrid.ColCount-1
      DefaultPropertyGrid.Cell(cj,ri)=""
    next
  next


  DefGridFileName$=StartDir+"data\"+objtype$+".data"
  call  AddClrString ("6965:DefGridFileName$="+(DefGridFileName$), clred, LogEdit)

  if fileexists (DefGridFileName$)>0 then
    DefaultPropertyGrid.LoadFromFile(DefGridFileName$,0,0,1000)

  else
    'objtype$="qpanel" '"trim$(field$(objtype$," ",1))
    'call  AddClrString ("2101:objtype$="+(objtype$), clb, LogEdit)
    'DefGridFileName$=StartDir+"data\"+objtype$+".data"
    'DefaultPropertyGrid.LoadFromFile(DefGridFileName$,0,0,1000)
    'Showmessage ("7011: File not found "+DefGridFileName$)
  end if


  GridFileName$=projectDir$+"\"+objname$+".dat"
  call  AddClrString ("**** 6981:GridFileName$="+(GridFileName$), clp, LogEdit)
  PropertyGrid.LoadFromFile(GridFileName$,0,0,1000) ' загружаем таблицу свойств для компонента из списка



  '!! Перебираем по таблице свойств и если свойство отлично от дефолтного - добавляем

  for ri=1 to PropertyGrid.RowCount-1
    if PropertyGrid.Cell(0,ri)="" then goto nextri

    if PropertyGrid.Cell(1,ri)="" or _
    ucase$(PropertyGrid.Cell(0,ri))=ucase$("Parent") or _
    instr(PropertyGrid.Cell(1,ri),"<") or _
    ucase$(PropertyGrid.Cell(0,ri))=ucase$("Handle") then
    'CodeText.AddStrings "'"+PropertyGrid.Cell(0,ri)+"="+PropertyGrid.Cell(1,ri)  '"CREATE "+token+" AS QFORM"
  else

    CodeText.AddStrings spacer+PropertyGrid.Cell(0,ri)+"="+PropertyGrid.Cell(1,ri)  '"CREATE "+token+" AS QFORM"

  end if
  nextri:
next




brem 0
=====================
erem

END SUB

'*****************************************
' Recursively called for each new "parent type" object
SUB InsertThisChain(StartIdx AS integer, lev AS integer)'!!!! <<< необновленные процедуры
  'call  AddClrString ("6963:InsertThisChain lev="+str$(lev), clp, LogEdit)
  'call  AddClrString ("6963:InsertThisChain StartIdx="+str$(StartIdx), clp, LogEdit)
  DEFINT i, cnt, nxt
  DEFSTR sibString, spacer

  spacer=SPACE$(lev*4)
  sibString=FillSiblingList(StartIdx) ' Get list of child object indexes
  'call  AddClrString ("6970:sibString="+(sibString), clred, LogEdit)
  'cnt=TALLY(sibString,"|")


  cnt=TALLY(sibString,"|")
  'call  AddClrString ("6976:cnt="+str$(cnt), clred, LogEdit)

  IF cnt>0 THEN
    FOR i=1 TO cnt                      ' Loop all child objects
      nxt=VAL(FIELD$(sibString,"|",i))  ' Get next object index
      'call  AddClrString ("6981:nxt="+str$(nxt), clred, LogEdit)
      InsertObjectCode(nxt,lev)         ' Add this object code

      IF IsTypeParent(nxt)=True THEN    ' Child objects?
        INC lev
        call  AddClrString ("6988:lev="+str$(lev), cldr, LogEdit)
        InsertThisChain(nxt,lev)        ' Recursive call to self
        DEC lev
      END IF
      CodeText.AddStrings spacer+"END CREATE" ' Terminate this object code
    NEXT i
  END IF


END SUB



'!*****************************************
SUB BuildFormCode1'

  DEFINT i, ObjIdx,ObjLvl=-1 ' уровень вложенности родителей-детей
  DEFSTR tstr, ObjType, ObjName


  FOR i=0 TO ObjectCount-1 ' перебираем по объектам
    call  AddClrString ("6919:ObjectType("+str$(i)+")="+(ObjectType(i)), cldb, LogEdit)

    objType=ucase$(ObjectType(i))
    ObjName=ucase$(ObjectName(i))
    ObjIdx=i

    SELECT CASE objType

    CASE "QFORM","QSCROLLBOX","QPANEL","QGROUPBOX","QTABCONTROL"  ' объекты могут иметь детей

      CodeText.AddStrings "Create "+ObjectName(i)+" as "+ObjectType(i)
      inc ObjLvl
      CodeText.AddStrings "End Create "

    CASE ELSE                                                   '

    END SELECT



    if ObjectHandle(ObjParentIdx(i))=Parnt and ObjectType(i)=ComponentType then
      'MessageBox("Only one instance per parent object allowed!","RapidFRM "+VER,&h30)
      'Result=True
      'EXIT FUNCTION
    END IF
  NEXT i


END SUB


'!*****************************************
' Entry point to display the code for current form(s) layout
SUB BuildFormCode
  call  AddClrString ("3501:BuildFormCode="+str$(BuildFormCode), clg, LogEdit)
  DEFINT i, j, lev=1
  DEFSTR tstr, ObjType, ObjName


  CodeText.Clear
  IF ProjectMode=STAND_ALONE THEN
    InsertCodeHeader                                            '! New project code header
  END IF

  IF LTRIM$(PopMenuList)<>"" THEN                                 ' QPOPUPMENUs B4 main code
    'InsertMenu(POPMENU)
  END IF

  'call  AddClrString ("6993:ObjectCount="+str$(ObjectCount), clred, LogEdit)
  'exit sub

  'FOR i=0 TO ObjectIndex-1                                 ' Loop through the AddedObjectList...
  FOR i=0 TO ObjectCount-1                                 ' Loop through the AddedObjectList...
    'tstr=FIELD$(AddedObjectList(i),"~",1)                            ' ..for form objects
    objType=ucase$(ObjectType(i))
    call  AddClrString ("6998:objType="+(objType), clred, LogEdit)
    ObjName=ucase$(ObjectName(i))
    call  AddClrString ("7000:ObjName="+(ObjName), clred, LogEdit)



    tstr=objType '"QFORM"
    'IF FIELD$(tstr,"|",1)="0" THEN                              ' Type QFORM?
    IF tstr="QFORM" THEN                              ' Type QFORM?
      call  AddClrString ("6984:ObjName="+(ObjName), clred, LogEdit)
      InsertFormCode(i)                                       ' Add the initial form code
      InsertThisChain(i,lev)                                  ' Add ALL child code
      CodeText.AddStrings "END CREATE",""                     ' Add the form terminate code
    END IF
  NEXT i



  for ri=1 to PropertyGrid.RowCount-1  '! очищаем  PropertyGrid
    for cj=0 to PropertyGrid.ColCount-1
      PropertyGrid.Cell(cj,ri)=""
    next
  next

  PropertyGrid.RowCount=2
  GridFileName$=projectDir$+"\"+trim$(ObjectName(ObjectIndex))+".dat"
  call  AddClrString ("7388:GridFileName$="+(GridFileName$), clred, LogEdit)

  PropertyGrid.LoadFromFile(GridFileName$,0,0,1000) ' загружаем таблицу свойств для компонента из списка


END SUB

'---------------------- Stand-alone saving code clipboard/file------------------------------------
'NB CodeText.CopyToClipboard not used .. clipboard cleared on exit of program
'!*****************************************
SUB CopyToClipBrd
  ClipBoard.Open
  ClipBoard.Clear                                                 ' Dump any contents
  IF DesignTab.Tag=2 THEN                                         ' RapidQ TAB page visible
    CodeText.SelectAll
    ClipBoard.Text=CodeText.Text                                ' Throw the lot onto the clipboard
    ClipBoard.Close                                             ' Remains when exiting
    CodeText.SelLength=0                                        ' De-select text
  ELSE
    FBCodeText.SelectAll                                         ' FreeBasic code
    ClipBoard.Text=FBCodeText.Text
    ClipBoard.Close
    FBCodeText.SelLength=0
  END IF
  ComponentCount=ObjectIndex                                      ' Signal we have saved and can exit ok
  MessageBox("Your code has been placed on the clipboard","RapidFRM "+VER,&H40)
END SUB

'!*****************************************
SUB SelectionToClipBrd
  IF DesignTab.Tag=2 THEN                                         ' RapidQ TAB page visible
    IF CodeText.SelLength>0 THEN
      ClipBoard.Open
      ClipBoard.Clear                                         ' Dump any contents
      ClipBoard.Text=CodeText.SelText                         ' Selection onto the clipboard
      ClipBoard.Close                                         ' Remains when exiting
      CodeText.SelLength=0                                    ' De-select text
      ComponentCount=ObjectIndex                              ' Signal we have saved and can exit ok
      MessageBox("RapidQ code snippet has been placed on the clipboard","RapidFRM "+VER,&H40)
    ELSE
      MessageBox("No code has been selected","RapidFRM "+VER,&H30)
    END IF
  ELSE
    IF FBCodeText.SelLength>0 THEN                               ' FreeBasic code
      ClipBoard.Open
      ClipBoard.Clear
      ClipBoard.Text=FBCodeText.SelText                        ' Selection onto the clipboard
      ClipBoard.Close
      FBCodeText.SelLength=0
      ComponentCount=ObjectIndex                              ' Signal we have saved and can exit ok
      MessageBox("FreeBasic code snippet has been placed on the clipboard","RapidFRM "+VER,&H40)
    ELSE
      MessageBox("No code has been selected","RapidFRM "+VER,&H30)
    END IF
  END IF
END SUB

'!*****************************************
' Save as either RapidQ or FreeBasic source code
SUB SaveFile
  DIM SaveDialog AS QSAVEDIALOG
  DEFSTR tstr

  SaveDialog.Filter="BAS file|*.bas|INC file|*.inc|TEXT file|*.txt"
  IF SaveDialog.Execute THEN
    IF INSTR(SaveDialog.FileName,".")=0 THEN
      tstr=FIELD$(Savedialog.Filter,"*",Savedialog.FilterIndex+1)
      SaveDialog.FileName=SaveDialog.FileName+LEFT$(tstr,4)
    END IF
    IF DesignTab.Tag=2 THEN                                     ' RapidQ TAB page visible
      CodeText.SaveToFile SaveDialog.FileName
    ELSE
      FBCodeText.SaveToFile SaveDialog.FileName                ' FreeBasic visible
    END IF
    ComponentCount=ObjectIndex                                  ' Signal we have saved and can exit ok
  END IF
END SUB

'----------------------- Visually adding new components -------------------------------------
' Entry points AddNewObject() or AddNewForm()

'!*****************************************
FUNCTION GetDefaultProperties(ComponentID)'!!!! <<< необновленные процедуры
  DEFINT i, j
  DEFSTR tstr, token

  ComponentRef.Position=0                                         ' Stream contains default data ALL components
  token="# "+STR$(ComponentID): j=LEN(token)                      ' Components start with "# <ID> <Q-COMPONENT_NAME>"

  FOR i=1 TO ComponentRef.LineCount
    tstr=ComponentRef.Readline
    IF LEFT$(tstr,j)=token THEN
      EXIT FOR
    END IF
  NEXT i

  IF i>ComponentRef.LineCount THEN                                ' Just in case!
    tstr="GetDefaultProperties() - Component "+STR$(ComponentID)+" NOT found!"
    MessageBox(tstr,"RapidFRM "+VER,&h30)
    Result=""
    EXIT FUNCTION
  END IF

  tstr=""
  token=ComponentRef.Readline
  WHILE LEFT$(token,1)<>"#"
    tstr=tstr+token+"~"                                         ' All properties this component
    token=ComponentRef.Readline
  WEND
  Result=tstr
END FUNCTION

'!*****************************************
SUB UpdatePropGrid(idx)'!!!! <<< необновленные процедуры
  call  AddClrString ("3505:UpdatePropGrid="+str$(UpdatePropGrid), clg, LogEdit)

  DEFINT i, propCount, methodCount, eventCount, maxStrings
  DEFSTR propString, tstr, token

  SelectionCombo.ItemIndex=idx

  propString=AddedObjectList(idx)                                      ' Properties & events this object
  tstr=FIELD$(propString,"~",1)                                   ' Header field string
  IF ProjectMode=STAND_ALONE THEN
    token=FIELD$(tstr,"|",4)                                    ' Internal object name
  ELSE
    token=FIELD$(tstr,"|",5)                                    ' Project object name
  END IF

  maxStrings=TALLY(propString,"~")
  propCount=0: methodCount=0: eventCount=0
  FOR i=2 TO maxStrings
    tstr=FIELD$(propString,"~",i)
    IF LEFT$(tstr,1)="*" THEN EXIT FOR                          ' Finished with properties?
    INC propCount                                               ' Component property
    IF (propCount+1)=PropertyGrid.RowCount THEN PropertyGrid.InsertRow(propCount)
    PropertyGrid.Cell(0,propCount)=FIELD$(tstr,"|",1)
    PropertyGrid.Cell(1,propCount)=FIELD$(tstr,"|",4)
  NEXT i
  FOR i=i+1 TO maxStrings
    tstr=FIELD$(propString,"~",i)
    IF LEFT$(tstr,1)="*" THEN EXIT FOR                          ' Finished with methods?
    INC methodCount                                             ' Component method
    IF (methodCount+1)=MethodGrid.RowCount THEN MethodGrid.InsertRow(methodCount)
    MethodGrid.Cell(0,methodCount)=FIELD$(tstr,"|",1)
    MethodGrid.Cell(1,methodCount)=FIELD$(tstr,"|",4)
  NEXT i
  FOR i=i+1 TO maxStrings
    tstr=FIELD$(propString,"~",i)
    INC eventCount                                              ' Component Event
    IF (eventCount+1)=EventGrid.RowCount THEN EventGrid.InsertRow(eventCount)
    EventGrid.Cell(0,eventCount)=FIELD$(tstr,"|",1)
    EventGrid.Cell(1,eventCount)=FIELD$(tstr,"|",2)
  NEXT i
  IF propCount=0 THEN                                             ' Some DirectX components!!
    propCount=1
    PropertyGrid.Cell(0,1)="No properties"
    PropertyGrid.Cell(1,1)=""
  END IF
  IF methodCount=0 THEN
    methodCount=1
    MethodGrid.Cell(0,1)="No design methods"
    MethodGrid.Cell(1,1)=""
  END IF
  IF eventCount=0 THEN
    eventCount=1
    EventGrid.Cell(0,1)="No events"
    EventGrid.Cell(1,1)=""
  END IF
  IF PropertyGrid.RowCount>(propCount+1) THEN
    FOR i=(propCount+2) TO PropertyGrid.RowCount
      PropertyGrid.DeleteRow(i)
    NEXT i
  END IF
  IF MethodGrid.RowCount>(methodCount+1) THEN
    FOR i=(methodCount+2) TO MethodGrid.RowCount
      MethodGrid.DeleteRow(i)
    NEXT i
  END IF
  IF EventGrid.RowCount>(eventCount+1) THEN
    FOR i=(eventCount+2) TO EventGrid.RowCount
      EventGrid.DeleteRow(i)
    NEXT i
  END IF
  PropertyValueUpdate
  ReDrawComponent
  ReDrawComponentbyField
  call  AddClrString ("6981:ReDrawComponentbyField="+str$(ReDrawComponentbyField), 0, LogEdit)

  UpdateStatus
END SUB


'!*****************************************
SUB AddNewForm ()
  call  AddClrString ("------------------------- 7465:AddNewForm="+str$(AddNewForm), clg, LogEdit)

  inc FormCount 'был 0 , стал 1
  inc ObjectCount 'был 0 , стал 1
  'call  AddClrString ("2439:AddNewForm FormCount="+str$(FormCount), subclr, LogEdit)
  'call  AddClrString ("2439:AddNewForm ObjectCount="+str$(ObjectCount), subclr, LogEdit)

  DEFINT i
  DEFSTR tstr, token

  FieldEdit.Visible=False
  FieldBox.Visible=False
  OldRow=-1


  FormIndex=FormCount-1
  call  AddClrString ("7465:FormIndex="+str$(FormIndex), clred, LogEdit)
  '!ObjectIndex=ObjectCount-1

  IF FormCount > MAX_FORMS THEN
    MessageBox("1712: Maximum forms ("+STR$(MAX_FORMS)+") has been reached","RapidFRM "+VER,&H30)
    EXIT SUB
  END IF

  ScanTimer.Enabled=False
  ''call  AddClrString ("3314:ScanTimer.Enabled="+str$(ScanTimer.Enabled), clred, LogEdit)
  CaretsTimer.Enabled=False
  FOR i=1 TO 8
    Carets(i).Parent=Forms(FormIndex)                            ' Set carets to this form
    Carets(i).Visible=False
  NEXT i

  call  AddClrString ("1719:ObjectCount="+str$(ObjectCount), clred, LogEdit)

  ObjTypeIndex(ObjectIndex)=FormIndex
  call  AddClrString ("7493:FormIndex="+str$(FormIndex), clred, LogEdit)

  'if flParsed=1 then

  ObjectType(ObjectIndex)="QForm" 'ObjNameGrid.Cell(1,1)

  'call  AddClrString ("2562:AddNewForm ReDrawComponentByField="+str$(ReDrawComponentByField), clb, LogEdit)


  ReDrawComponentByField '<<<<<<<<<<<<<<<<!!!!!!


  Forms(FormIndex).Show
  'call  AddClrString ("6729:FormIndex="+str$(FormIndex), clo, LogEdit)
  ObjectHandle(ObjectIndex)=Forms(FormIndex).handle
  'call  AddClrString ("2601:AddNewForm ObjectHandle("+str$(ObjectIndex)+")="+str$(ObjectHandle(ObjectIndex)), cldb, LogEdit)
  'call  AddClrString ("2483:AddNewForm Forms("+str$(FormIndex)+"handle)="+str$(Forms(FormIndex).handle), cldb, LogEdit)
  'flParsed=0

  'call  AddClrString ("6666666666666666666  7041:flParsed="+str$(flParsed), 0, LogEdit)
  call  AddClrString ("7511:flParsed="+str$(flParsed), clred, LogEdit)

  if flParsed=1 then

    goto exitAddNewFormSub '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  else

  end if

  token="Form"+STR$(FormIndex)
  ObjectName(ObjectIndex)=token
  FormName(FormIndex)=token

  ObjNameGrid.Cell(0,1)=FormName(FormIndex)
  ObjNameGrid.Cell(1,1)="QForm"

  PropertyGrid.cell(0,1)=ObjNameGrid.Cell(0,1)
  PropertyGrid.cell(1,1)=ObjNameGrid.Cell(1,1)

  'ObjectType(ObjectIndex)=ObjNameGrid.Cell(1,1)

  '!!! logedit as qrichedit  parent=form as qform
  token=token+" as QForm"
  cmboxObj.addItems token
  'call  AddClrString ("2596:token="+str$(token), clred, LogEdit)
  cmboxObj.ItemIndex=ObjectIndex

  '!!!  заменяем на сохранение свойств формы  в таблицу и таблицы в файл таблицы  <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  '1 заполняем таблицу свойствами по умолчанию
  for ri=0 to DefaultPropertyGrid.RowCount-1
    for cj=0 to DefaultPropertyGrid.ColCount-1
      DefaultPropertyGrid.Cell(cj,ri)=""
    next
  next


  DefaultPropertyGrid.LoadFromFile(StartDir+"\data\QFORM.data",0,0,1000)
  PropertyGrid.RowCount= DefaultPropertyGrid.RowCount+1
  'call  AddClrString ("2504:DefaultPropertyGrid.ColCount="+str$(DefaultPropertyGrid.RowCount), clp, LogEdit)

  brem 0
  =====================
  ===================
  erem

  evRow=1

  for ri=0 to EventGrid.RowCount-1
    for cj=0 to EventGrid.ColCount-1
      EventGrid.Cell(cj,ri)=""
    next
  next


  for i=1 to PropertyGrid.RowCount-1

    'if lcase$(left$(DefaultPropertyGrid.cell(0,i-1),2))="on" then
    'EventGrid.cell(0,evRow)=DefaultPropertyGrid.cell(0,i-1)
    'inc evRow
    'if EventGrid.RowCount<evRow then EventGrid.RowCount=evRow

    'call  AddClrString ("7560:evRow="+str$(evRow), clred, LogEdit)
    'else
    PropertyGrid.cell(0,i)=DefaultPropertyGrid.cell(0,i-1) ' невидимая таблица для DefaultProperty
    PropertyGrid.cell(1,i)=DefaultPropertyGrid.cell(2,i-1)
    PropertyGrid.cell (4,i)=DefaultPropertyGrid.cell (1,i-1)

    'end if



  next i

  evRow=1

  for i=1 to PropertyGrid.RowCount-1
    'call  AddClrString ("14657:lcase$("+str$(i)+")="+(lcase$(left$(DefaultPropertyGrid.cell(0,i-1),2))), clred, LogEdit)

    'if lcase$(left$(DefaultPropertyGrid.cell(0,i-1),2))="on" then
    'EventGrid.cell(0,evRow)=DefaultPropertyGrid.cell(0,i-3)
    'inc evRow
    'else
    PropertyGrid.cell(3,i)=str$(i) ' номер строки
    PropertyGrid.cell(1,i)=DefaultPropertyGrid.cell(2,i-1)
    'end if
  next i




  qq=2
  PropertyGrid.cell(1,3-qq)=str$(Forms(FormIndex).Left)
  call  AddClrString ("7591:Forms("+str$(FormIndex)+"Left)="+str$(Forms(FormIndex).Left), clred, LogEdit)
  PropertyGrid.cell(1,4-qq)=str$(Forms(FormIndex).Top)
  call  AddClrString ("7593:Forms("+str$(FormIndex)+"Top)="+str$(Forms(FormIndex).Top), clred, LogEdit)
  PropertyGrid.cell(1,5-qq)=str$(Forms(FormIndex).Width)
  call  AddClrString ("7595:Forms("+str$(FormIndex)+"Width)="+str$(Forms(FormIndex).Width), clred, LogEdit)
  PropertyGrid.cell(1,6-qq)=str$(Forms(FormIndex).Height)
  call  AddClrString ("7597:Forms("+str$(FormIndex)+"Height)="+str$(Forms(FormIndex).Height), clred, LogEdit)
  PropertyGrid.cell(1,7-qq)=str$(Forms(FormIndex).AutoScroll)
  PropertyGrid.cell(1,9-qq)=Forms(FormIndex).Caption
  call  AddClrString ("7600:Forms("+str$(FormIndex)+"Caption)="+(Forms(FormIndex).Caption), clred, LogEdit)
  PropertyGrid.cell(1,16-qq)=str$(Forms(FormIndex).Handle)
  call  AddClrString ("7602:Forms("+str$(FormIndex)+"Handle)="+str$(Forms(FormIndex).Handle), clred, LogEdit)
  'PropertyGrid.cell(1,18)=str$(Forms(FormIndex).IcoHandle)
  'PropertyGrid.cell(1,23)=(Forms(FormIndex).PopUpMenu)
  PropertyGrid.cell(1,22-qq)=str$(Forms(FormIndex).Parent)
  'SillyForm.Handle

  '!!! сохраняем таблицу
  if projectDir$="" then ' создаем новый проект
    'projectDir$=StartDir+projectpath$+"Newproject "+time$-":"
    projectDir$=projectpath$+"Newproject "+time$-":"
    'projectDir$=ExtractFileName(SrcFileName$)
    'projectDir$=FileNameNoExt(projectDir$)
    'projectDir$=projectpath$+projectDir$
    ''call  AddClrString ("962:projectDir$="+(projectDir$), clred, LogEdit)
    if direxists(projectDir$)=0 then
      mkdir projectDir$
    end if
  end if

  PropertyValueUpdate ' update cont alias to value

  'GridFileName$=projectDir$+"\"+trim$(PropertyGrid.Cell(0,1))+".dat"
  GridFileName$=projectDir$+"\"+trim$(field$(cmboxObj.text," ",1))+".dat"
  'GridFileName$=projectDir$+"\"+trim$(field$(cmboxObj.Item(cmboxObj.ItemIndex)," ",1)+".dat")

  'call  AddClrString ("2659:AddNewForm  Сохраняем в GridFileName$="+(GridFileName$), cldr, LogEdit)
  PropertyGrid.SaveToFile(GridFileName$,0,0,PropertyGrid.RowCount)

  exitAddNewFormSub:

  NewObjectID=-1
  'call  AddClrString ("=========2980:FormIndex="+str$(FormIndex), clred, LogEdit)
  'call  AddClrString ("======== 2980:ObjectIndex="+str$(ObjectIndex), cldb, LogEdit)
  ScanTimer.Enabled=True
  'call  AddClrString ("2555:ScanTimer.Enabled="+str$(ScanTimer.Enabled), clp, LogEdit)

  'qa=GetNewObjectID ("QLABEL")

END SUB




'*****************************************
SUB AddNewForm_OLD
  'reDIM Forms(FrmIndex+1) AS QFORM
  call  AddClrString ("3313:FrmIndex="+str$(FrmIndex), clred, LogEdit)

  DEFINT i
  DEFSTR tstr, token

  IF FrmIndex > MAX_FORMS THEN
    MessageBox("Maximum forms ("+STR$(MAX_FORMS)+") has been reached","RapidFRM "+VER,&H30)
    EXIT SUB
  END IF

  ScanTimer.Enabled=False
  'call  AddClrString ("3314:ScanTimer.Enabled="+str$(ScanTimer.Enabled), clred, LogEdit)

  'DesignTab.TabIndex=0                                            ' Ensure design tab visible
  'DesignTabChange

  CaretsTimer.Enabled=False
  FOR i=1 TO 8
    Carets(i).Parent=Forms(FrmIndex)                            ' Set carets to this form
    Carets(i).Visible=False
  NEXT i

  FormIndex=FrmIndex: CurrentObject=ObjectIndex
  ObjTypeIndex(CurrentObject)=FrmIndex
  token="Form"+STR$(FrmIndex)
  call  AddClrString ("3338:token="+(token), clred, LogEdit)

  '!!!  заменяем на загрузку таблицы
  tstr=STR$(0)+"|QFORM|"+STR$(Forms(FrmIndex).Handle)+"|"+token+"|"+token+"|0~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(0)

  'PropertyGrid.LoadFromFile("\data\QFORM.data",0,0)


  '    BringWindowToTop(Forms(FrmIndex).Handle)
  SetWindowPos(Forms(FrmIndex).Handle,HWND_TOPMOST,0,0,0,0,FLAGS)
  Forms(FrmIndex).Show

  SelectionCombo.AddItems token+" [QFORM]"
  SelectionCombo.ItemIndex=CurrentObject

  INC ObjectIndex: INC FrmIndex: NewObjectID=-1
  ScanTimer.Enabled=True
  'call  AddClrString ("3338:ScanTimer.Enabled="+str$(ScanTimer.Enabled), clred, LogEdit)
END SUB

'!*****************************************
' When ONLY single instance of this object per form allowed
FUNCTION FormHasObject(ComponentID AS integer) AS integer '!!!! <<< необновленные процедуры
  DEFINT i, j, cnt, thisObject
  DEFSTR objStr, tstr

  FOR i=1 TO MAX_OBJECTS
    objStr=AddedObjectList(i)                                        ' Search for this object type
    IF objStr="" THEN EXIT FOR
    tstr=FIELD$(objStr,"~",1)
    thisObject=VAL(FIELD$(tstr,"|",1))
    IF thisObject=ComponentID THEN
      cnt=TALLY(objStr,"~")
      FOR j=1 TO cnt                                          ' Check if object belongs to this form
        tstr=FIELD$(objStr,"~",j)
        IF FIELD$(tstr,"|",1)="Parent" THEN
          tstr=FIELD$(tstr,"|",4)                         ' Parent form name
          IF VAL(RIGHT$(tstr,1))=FormIndex THEN
            MessageBox("Only one instance per form allowed!","RapidFRM "+VER,&h30)
            Result=True
            EXIT FUNCTION
          END IF
        END IF
      NEXT j
    END IF
  NEXT i
  Result=False
END FUNCTION

'!*****************************************
' When ONLY single instance of this object per parent object allowed
FUNCTION ParentHasObject(Parnt AS long, ComponentID AS integer, ComponentType AS string) AS integer'!!!! <<< необновленные процедуры
  DEFINT i, parntIdx
  DEFSTR tstr

  'DIM ObjectType(0 TO MAX_OBJECTS) AS string       '!! Component's type ie  QPANEL, QButton etc
  'DIM ObjTypeIndex(0 TO MAX_OBJECTS) as integer  ' !!index of an object in the type group ie ObjTypeIndex(ObjIndex)
  'DIM ObjectHandle(0 TO MAX_OBJECTS) AS long     '!! Component's handle
  'DIM ObjectName(0 TO MAX_OBJECTS) AS string     '!! Component's name  ie Edit1, Panel1, StrinGrid3 etc
  'dim ObjVisible(0 TO MAX_OBJECTS) AS integer  ' !! component(ObjectIndex) - visible or nonvisible
  'dim ObjParentIdx(0 TO MAX_OBJECTS) AS integer  ' !! ObjectIndex of the parents of the component(ObjectIndex)

  'well.. if component(ObjectIndex) has a parent - ObjectIndex of this parent stored in ObjParentIdx(ObjectIndex),so
  'handle of the parent of component(ObjectIndex) stored in ObjectHandle(ObjParentIdx(ObjectIndex))



  'FOR i=1 TO ObjectIndex-1
  'tstr=FIELD$(AddedObjectList(i),"~",1)                            ' Search for any existing ComponentIDs
  'IF ComponentID=VAL(FIELD$(tstr,"|",1)) THEN
  'IF VAL(FIELD$(tstr,"|",6))=Parnt THEN                   ' This parent has this object type already
  'MessageBox("Only one instance per parent object allowed!","RapidFRM "+VER,&h30)
  'Result=True
  'EXIT FUNCTION
  'END IF
  'END IF
  'NEXT i

  FOR i=0 TO ObjectCount-1
    call  AddClrString ("6957:ObjectType("+str$(i)+")="+str$(ObjectType(i)), cldb, LogEdit)

    if ObjectHandle(ObjParentIdx(i))=Parnt and ObjectType(i)=ComponentType then
      MessageBox("Only one instance per parent object allowed!","RapidFRM "+VER,&h30)
      Result=True
      EXIT FUNCTION
    END IF
  NEXT i


  Result=False
END FUNCTION


'!*****************************************
FUNCTION WhichParent(hWnd AS long) AS string
  'call  AddClrString ("3922:WhichParent hWnd="+str$(hWnd), subclr, LogEdit)
  DEFINT i
  DEFSTR tstr

  Result=""
  FOR i=0 TO ObjectIndex-1
    ''call  AddClrString ("3929:ObjectHandle("+str$(I)+")="+str$(ObjectHandle(I)), clb, LogEdit)

    IF hWnd=ObjectHandle(I) THEN                        ' Is this the handle?
      ''call  AddClrString ("3929:ObjectHandle("+str$(I)+")="+str$(ObjectHandle(I)), cllr, LogEdit)
      Result=ObjectName(I)                               ' Object name
      EXIT FOR
    END IF
  NEXT i
END FUNCTION



'*****************************************
' Return the name of the object parent
FUNCTION WhichParent1(hWnd AS long) AS string'!!!! <<< необновленные процедуры
  DEFINT i
  DEFSTR tstr

  Result=""
  FOR i=0 TO ObjectIndex-1
    tstr=FIELD$(AddedObjectList(i),"~",1)                            ' Each object in list
    IF hWnd=VAL(FIELD$(tstr,"|",3)) THEN                        ' Is this the handle?
      Result=FIELD$(tstr,"|",5)                               ' Object name
      EXIT FOR
    END IF
  NEXT i
END FUNCTION

'!!! =========== adding components ====================
SUB AddQOVALBTN(hWnd AS long)
  'STATIC QOVALIndex
  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  REDIM panelOval(QOVALCount) AS QPANEL
  reDIM Ovalb(QOVALCount) AS QOVALBTN
  QOVALIndex=QOVALCount-1
  inc QOVALCount


  token="OvalBtn"+STR$(QOVALIndex)+" "

  'panelOval(QOVALIndex).Parent=Forms(FormIndex)                            ' MUST set a valid parent first!
  'IF hWnd<>Forms(FormIndex).Handle THEN
  'SetParent(panelOval(QOVALIndex).Handle,hWnd)                           ' Set to correct parent
  'END IF

  prnt$=GetQParent (hWnd)

  prntName$=field$(prnt$,"_",1)
  call  AddClrString ("5724:prntName$="+(prntName$), clred, LogEdit)

  prntIdx$=field$(prnt$,"_",2)
  call  AddClrString ("5726:prntIdx$="+(prntIdx$), clred, LogEdit)

  prntIndex=val(prntIdx$)

  Select case prntName$
  case "forms"
    panelOval(QOVALIndex).Parent=Forms(prntIndex)
  case "dpan"
    panelOval(QOVALIndex).Parent=dpan(prntIndex)
  case "grpbox"
    panelOval(QOVALIndex).Parent=grpbox(prntIndex)
  case "scrollb"
    panelOval(QOVALIndex).Parent=scrollb(prntIndex)
  case "BoxTab"
    panelOval(QOVALIndex).Parent=BoxTab(prntIndex)

  case else

  end select


  'call  AddClrString ("4276:panelOval("+str$(QOVALIndex)+")Handle)="+str$(panelOval(QOVALIndex).Handle), 0, LogEdit)
  ObjectType(ObjectIndex)="QOVALBTN"
  ObjTypeIndex(ObjectIndex)=QOVALIndex
  ObjectHandle(ObjectIndex)=panelOval(QOVALIndex).Handle
  ObjectName(ObjectIndex)="OVALBTN"+STR$(QOVALIndex) '!========================

  if flParsed=0 then ' свойства!!!  компонента, если он устанавливается с палитры

    tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
    ScreenToClient(hWnd,tPoint)
    panelOval(QOVALIndex).Left=tPoint.x
    panelOval(QOVALIndex).Top=tPoint.y
    'panelOval(QOVALIndex).Width=75                                             ' Using a QPanel so MUST set...
    'panelOval(QOVALIndex).Height=40                                            ' .. these to the defaults of QOvalBtn
    panelOval(QOVALIndex).BevelWidth=0
    panelOval(QOVALIndex).Caption=token
    panelOval(QOVALIndex).Color=clr

    Ovalb(QOVALIndex).Parent=panelOval(QOVALIndex)
    Ovalb(QOVALIndex).Align=alClient
    Ovalb(QOVALIndex).Enabled=False                                        ' Passes clicks thru to panel
    Ovalb(QOVALIndex).Tag=QOVALIndex
    Ovalb(QOVALIndex).Color=cla
    Ovalb(QOVALIndex).Caption=token


    ObjectType(ObjectIndex)="QOVALBTN"
    ObjTypeIndex(ObjectIndex)=QOVALIndex

    PropertyFieldUpdate("Left",STR$(tPoint.x))                    '
    PropertyFieldUpdate("Top",STR$(tPoint.y))                     ' Update new properties in AddedObjectList..
    PropertyFieldUpdate("Caption",token)                          ' ..Width & Height defaults
    PropertyFieldUpdate("Parent",WhichParent(hWnd))               '

    'SaveNewObjDataGrid(hWnd, token, ObjectIndex) '!!! сохранение таблицы
    SaveNewObjDataGrid(hWnd, token, ObjectIndex,tPoint.x, tPoint.y, panelOval(QOVALIndex).Width, panelOval(QOVALIndex).Height,panelOval(QOVALIndex).Color) '!!! сохранение таблицы
  else
    ReDrawComponentByField

  end if

  'UpdatePropGrid(ObjectIndex)                                   ' Update String grid
  'INC ObjectCount: INC QOVALIndex

END SUB

'*****************************************
SUB AddQCHECKBOX(hWnd AS long)
  'call  AddClrString ("4378:AddQCHECKBOX parent hwnd="+str$(hWnd), subclr, LogEdit)
  'reDIM Check(CheckIndex+1) AS QCHECKBOX
  '!DIM Check(32) AS QCHECKBOX

  reDIM Check(CheckCount) AS QCHECKBOX

  CheckIndex=CheckCount-1
  inc CheckCount


  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  'with Check(CheckIndex)

  Check(CheckIndex).Parent=Forms(FormIndex)                     ' MUST set a valid parent first!
  IF hWnd<>Forms(FormIndex).Handle THEN
    SetParent(Check(CheckIndex).Handle,hWnd)                    ' Set to correct parent
  END IF

  ObjectType(ObjectIndex)="QCHECKBOX"
  ObjTypeIndex(ObjectIndex)=CheckIndex
  ObjectHandle(ObjectIndex)=Check(CheckIndex).Handle
  token="CHECKBOX"+str$(CheckIndex)+" "

  ObjectName(ObjectIndex)=token ' список имен объектов
  'call  AddClrString ("4426:token="+str$(token), clo, LogEdit)
  'call  AddClrString ("4391:ObjectName("+str$(ObjectIndex)+")="+(ObjectName(ObjectIndex)), clo, LogEdit)


  if flParsed=0 then ' свойства!!!  компонента, если он устанавливается с палитры

    token="ChkBox"+STR$(CheckIndex)

    Check(CheckIndex).Caption=token
    ObjectName(ObjectIndex)=token


    tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
    ScreenToClient(hWnd,tPoint)
    Check(CheckIndex).Left=tPoint.x
    Check(CheckIndex).Top=tPoint.y
    Check(CheckIndex).Width=100
    Check(CheckIndex).Height=20
    'ObjectIndex=ObjectIndex

    PropertyFieldUpdate("Left",STR$(tPoint.x))                    '
    PropertyFieldUpdate("Top",STR$(tPoint.y))                     ' Update new properties in AddedObjectList..
    PropertyFieldUpdate("Caption",token)                          ' ..Width & Height defaults
    PropertyFieldUpdate("Parent",WhichParent(hWnd))               '
    'SaveNewObjDataGrid(hWnd, token, ObjectIndex) '!!! сохранение таблицы
    SaveNewObjDataGrid(hWnd, token, ObjectIndex,tPoint.x, tPoint.y, .Width, .Height,0) '!!! сохранение таблицы
  else
    ReDrawComponentByField
  end if

  'end with

END SUB

'*****************************************
SUB AddQLabel(hWnd AS long)
  call  AddClrString ("7104:hWnd="+str$(hWnd), clred, LogEdit)
  reDIM BoxLabel(LabelCount) AS Qpanel 'QLabel

  LabelIndex=LabelCount-1
  inc LabelCount

  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  BoxLabel(LabelIndex).BorderStyle=bpNone
  BoxLabel(LabelIndex).BevelWidth=0

  'BoxLabel(LabelIndex).Parent=Forms(FormIndex)                     ' MUST set a valid parent first!
  'IF hWnd<>Forms(FormIndex).Handle THEN
  'SetParent(BoxLabel(LabelIndex).Handle,hWnd)                    ' Set to correct parent
  'END IF

  '!----------------'! new procedure for get parent --------------
  prnt$=GetQParent (hWnd)
  prntName$=field$(prnt$,"_",1)
  call  AddClrString ("5724:prntName$="+(prntName$), clred, LogEdit)
  prntIdx$=field$(prnt$,"_",2)
  call  AddClrString ("5726:prntIdx$="+(prntIdx$), clred, LogEdit)
  prntIndex=val(prntIdx$)

  Select case prntName$
  case "forms"
    BoxLabel(LabelIndex).Parent=Forms(prntIndex)
  case "dpan"
    BoxLabel(LabelIndex).Parent=dpan(prntIndex)
  case "grpbox"
    BoxLabel(LabelIndex).Parent=grpbox(prntIndex)
  case "scrollb"
    BoxLabel(LabelIndex).Parent=scrollb(prntIndex)
  case "BoxTab"
    BoxLabel(LabelIndex).Parent=BoxTab(prntIndex)

  case else

  end select
  '! -------------------------------------


  token="Label"+STR$(LabelIndex)+" "

  ObjectType(ObjectIndex)="QLABEL"
  ObjTypeIndex(ObjectIndex)=LabelIndex
  'call  AddClrString ("4946:ObjTypeIndex("+str$(ObjectIndex)+")="+str$(ObjTypeIndex(ObjectIndex)), clb, LogEdit)
  ObjectHandle(ObjectIndex)=BoxLabel(LabelIndex).Handle
  'call  AddClrString ("4946:BoxLabel("+str$(LabelIndex)+"Handle)="+str$(BoxLabel(LabelIndex).Handle), clb, LogEdit)
  ObjectName(ObjectIndex)=token
  'ObjectIndex=ObjectIndex


  if flParsed=0 then ' свойства!!!  компонента, если он устанавливается с палитры

    BoxLabel(LabelIndex).Caption=token

    tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
    ScreenToClient(hWnd,tPoint)
    BoxLabel(LabelIndex).Left=tPoint.x
    BoxLabel(LabelIndex).Top=tPoint.y
    BoxLabel(LabelIndex).Width=100
    BoxLabel(LabelIndex).Height=20

    PropertyFieldUpdate("Left",STR$(tPoint.x))                    '
    PropertyFieldUpdate("Top",STR$(tPoint.y))                     ' Update new properties in AddedObjectList..
    PropertyFieldUpdate("Caption",token)                          ' ..Width & Height defaults
    PropertyFieldUpdate("Parent",WhichParent(hWnd))               '

    'SaveNewObjDataGrid(hWnd, token, ObjectIndex) '!!! сохранение таблицы
    SaveNewObjDataGrid(hWnd, token, ObjectIndex,tPoint.x, tPoint.y, BoxLabel(LabelIndex).Width,_
                       BoxLabel(LabelIndex).Height,BoxLabel(LabelIndex).Color) '!!! сохранение таблицы
  else
    ReDrawComponentByField
  end if


END SUB


'*****************************************
SUB AddQRADIOBUTTON(hWnd AS long)
  reDIM Radio(RadioCount) AS QRADIOBUTTON
  RadioIndex=RadioCount-1
  inc RadioCount

  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  'with Radio'(RadioIndex)
  Radio(RadioIndex).Parent=Forms(FormIndex)                     ' MUST set a valid parent first!
  IF hWnd<>Forms(FormIndex).Handle THEN
    SetParent(Radio(RadioIndex).Handle,hWnd)                    ' Set to correct parent
  END IF

  if childName$<>"" then
    token=childName$
  else
    token="RadioBtn"+STR$(RadioIndex) +" "
  end if

  'ObjectIndex=ObjectIndex

  token="RadioBtn"+STR$(RadioIndex) +" "


  ObjectType(ObjectIndex)="QRADIOBUTTON"
  ObjTypeIndex(ObjectIndex)=RadioIndex
  ObjectHandle(ObjectIndex)=Radio(RadioIndex).Handle
  ObjectName(ObjectIndex)=token
  'ObjectIndex=ObjectIndex

  'call  AddClrString ("4534:flParsed="+str$(flParsed), clb, LogEdit)

  if flParsed=0 then ' свойства!!!  компонента, если он устанавливается с палитры

    Radio(RadioIndex).Caption=token

    tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
    ScreenToClient(hWnd,tPoint)
    Radio(RadioIndex).Left=tPoint.x
    Radio(RadioIndex).Top=tPoint.y
    Radio(RadioIndex).Width=100
    Radio(RadioIndex).Height=20

    PropertyFieldUpdate("Left",STR$(tPoint.x))                    '
    PropertyFieldUpdate("Top",STR$(tPoint.y))                     ' Update new properties in AddedObjectList..
    PropertyFieldUpdate("Caption",token)                          ' ..Width & Height defaults
    PropertyFieldUpdate("Parent",WhichParent(hWnd))               '

    'SaveNewObjDataGrid(hWnd, token, ObjectIndex) '!!! сохранение таблицы
    SaveNewObjDataGrid(hWnd, token, ObjectIndex,tPoint.x, tPoint.y, Radio(RadioIndex).Width, Radio(RadioIndex).Height,Color) '!!! сохранение таблицы
  else
    ReDrawComponentByField
  end if


END SUB

'*****************************************
SUB AddQTABCONTROL(hWnd AS long)

  reDIM TabCtrl(TabContCount) AS QTABCONTROL
  reDIM BoxTab(TabContCount) AS QPANEL


  TabContIndex=TabContCount-1
  inc TabContCount

  ' QPanel as a container
  'DIM btn AS QBUTTON
  DEFLNG TabHandle
  DEFSTR tstr, token
  DIM tPoint AS PointAPI


  '!----------------'! new procedure for get parent --------------
  prnt$=GetQParent (hWnd)
  prntName$=field$(prnt$,"_",1)
  'call  AddClrString ("5724:prntName$="+(prntName$), clred, LogEdit)
  prntIdx$=field$(prnt$,"_",2)
  'call  AddClrString ("5726:prntIdx$="+(prntIdx$), clred, LogEdit)
  prntIndex=val(prntIdx$)

  Select case prntName$
  case "forms"
    BoxTab(TabContIndex).Parent=Forms(prntIndex)
  case "dpan"
    BoxTab(TabContIndex).Parent=dpan(prntIndex)
  case "grpbox"
    BoxTab(TabContIndex).Parent=grpbox(prntIndex)
  case "scrollb"
    BoxTab(TabContIndex).Parent=scrollb(prntIndex)
  case "BoxTab"
    BoxTab(TabContIndex).Parent=BoxTab(prntIndex)

  case else

  end select
  '! -------------------------------------

  ObjectType(ObjectIndex)="QTABCONTROL"
  ObjTypeIndex(ObjectIndex)=TabContIndex
  ObjectHandle(ObjectIndex)=BoxTab(TabContIndex).Handle
  call  AddClrString ("5551:BoxTab("+str$(TabContIndex)+").Handle)="+str$(BoxTab(TabContIndex).Handle), 0, LogEdit)
  ObjectName(ObjectIndex)=token

  TabCtrl(TabContIndex).Parent=BoxTab(TabContIndex)               '
  TabCtrl(TabContIndex).Align=alClient                            ' NB MUST do these AFTER container initialised
  TabCtrl(TabContIndex).AddTabs("T","A","B")
  '
  '!!! btn.Visible=False: btn.Parent=TabCtrl(TabContIndex) <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  'TabHandle=GetParent(btn.Handle)
  'call  AddClrString ("4238:TabHandle="+str$(TabHandle), clp, LogEdit)
  'DestroyWindow(btn.Handle)


  if flParsed=0 then ' свойства!!!  компонента, если он устанавливается с палитры

    BoxTab(TabContIndex).Width=150                                  ' Non-Default for a QTabControl...
    BoxTab(TabContIndex).Height=100                                 ' ...Re-sized for convenience
    BoxTab(TabContIndex).Borderstyle=0
    BoxTab(TabContIndex).BevelOuter=2

    token="TabCtrl"+STR$(TabContIndex)
    ObjectName(ObjectIndex)=token

    tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
    ScreenToClient(hWnd,tPoint)
    BoxTab(TabContIndex).Left=tPoint.x
    BoxTab(TabContIndex).Top=tPoint.y


    PropertyFieldUpdate("Left",STR$(tPoint.x))                    '
    PropertyFieldUpdate("Top",STR$(tPoint.y))                     ' Update new properties in AddedObjectList..
    PropertyFieldUpdate("Parent",WhichParent(hWnd))               '

    'SaveNewObjDataGrid(hWnd, token, ObjectIndex) '!!! сохранение таблицы
    SaveNewObjDataGrid(hWnd, token, ObjectIndex,tPoint.x, tPoint.y, BoxTab(TabContIndex).Width, BoxTab(TabContIndex).Height,BoxTab(TabContIndex).Color) '!!! сохранение таблицы
  else
    ReDrawComponentByField
  end if


END SUB





'*****************************************
' Minor problems with selecting this component at design time
SUB AddQCOMBOBOX(hWnd AS long)
  reDIM Combo(ComboCount) AS QCOMBOBOX
  'reDIM CPan(ComboCount) AS QPANEL


  ComboIndex=ComboCount-1
  inc ComboCount

  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  '!----------------'! new procedure for get parent --------------
  prnt$=GetQParent (hWnd)
  prntName$=field$(prnt$,"_",1)
  call  AddClrString ("5724:prntName$="+(prntName$), clred, LogEdit)
  prntIdx$=field$(prnt$,"_",2)
  call  AddClrString ("5726:prntIdx$="+(prntIdx$), clred, LogEdit)
  prntIndex=val(prntIdx$)

  Select case prntName$
  case "forms"
    Combo(ComboIndex).Parent=Forms(prntIndex)
  case "dpan"
    Combo(ComboIndex).Parent=dpan(prntIndex)
  case "grpbox"
    Combo(ComboIndex).Parent=grpbox(prntIndex)
  case "scrollb"
    Combo(ComboIndex).Parent=scrollb(prntIndex)
  case "BoxTab"
    Combo(ComboIndex).Parent=BoxTab(prntIndex)

  case else

  end select
  '! -------------------------------------


  ObjectType(ObjectIndex)="QCOMBOBOX"
  ObjTypeIndex(ObjectIndex)=ComboIndex
  ObjectHandle(ObjectIndex)=Combo(ComboIndex).Handle
  ObjectName(ObjectIndex)="COMBOBOX"+STR$(ComboIndex) '!========================

  if flParsed=0 then ' свойства!!!  компонента, если он устанавливается с палитры

    token="Combo"+STR$(ComboIndex)+_
    " as "+ObjectType(ObjectIndex)+" parent="+_
    ObjectName(ObjParentIdx(ObjectIndex))+" as "+ ObjectType(ObjParentIdx(ObjectIndex))


    Combo(ComboIndex).Text="Combo"+STR$(ComboIndex)
    Combo(ComboIndex).Width=145
    tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
    ScreenToClient(hWnd,tPoint)
    Combo(ComboIndex).Left=tPoint.x
    Combo(ComboIndex).Top=tPoint.y

    PropertyFieldUpdate("Left",STR$(tPoint.x))                    '
    PropertyFieldUpdate("Top",STR$(tPoint.y))                     ' Update new properties in AddedObjectList..
    PropertyFieldUpdate("Text",token)                             '
    PropertyFieldUpdate("Parent",WhichParent(hWnd))               '

    'SaveNewObjDataGrid(hWnd, token, ObjectIndex) '!!! сохранение таблицы
    SaveNewObjDataGrid(hWnd, token, ObjectIndex,tPoint.x, tPoint.y, Combo(ComboIndex).Width, Combo(ComboIndex).Height,Combo(ComboIndex).Color) '!!! сохранение таблицы
  else
    ReDrawComponentByField
  end if


END SUB

'*****************************************
SUB AddQLISTBOX(hWnd AS long)
  call  AddClrString ("4684:AddQLISTBOX= parent"+str$(hWnd), subclr, LogEdit)

  reDIM ListB(ListBCount) AS QLISTBOX

  ListBIndex=ListBCount-1
  inc ListBCount


  DEFSTR tstr, token
  DIM tPoint AS PointAPI


  prnt$=GetQParent (hWnd)

  prntName$=field$(prnt$,"_",1)
  call  AddClrString ("5724:prntName$="+(prntName$), clred, LogEdit)

  prntIdx$=field$(prnt$,"_",2)
  call  AddClrString ("5726:prntIdx$="+(prntIdx$), clred, LogEdit)

  prntIndex=val(prntIdx$)

  Select case prntName$
  case "forms"
    ListB(ListBIndex).Parent=Forms(prntIndex)
  case "dpan"
    ListB(ListBIndex).Parent=dpan(prntIndex)
  case "grpbox"
    ListB(ListBIndex).Parent=grpbox(prntIndex)
  case "scrollb"
    ListB(ListBIndex).Parent=scrollb(prntIndex)
  case "BoxTab"
    ListB(ListBIndex).Parent=BoxTab(prntIndex)

  case else

  end select




  ObjectType(ObjectIndex)="QLISTBOX"
  ObjTypeIndex(ObjectIndex)=ListBIndex
  ObjectHandle(ObjectIndex)=ListB(ListBIndex).Handle
  ObjectName(ObjectIndex)=token

  if flParsed=0 then ' свойства!!!  компонента, если он устанавливается с палитры

    token="ListBox"+STR$(ListBIndex)+_
    " as "+ObjectType(ObjectIndex)+" parent="+_
    ObjectName(ObjParentIdx(ObjectIndex))+" as "+ ObjectType(ObjParentIdx(ObjectIndex))


    call  AddClrString ("5685:token="+(token), clred, LogEdit)
    ListB(ListBIndex).Width=120
    ListB(ListBIndex).Height=100
    tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
    ScreenToClient(hWnd,tPoint)
    ListB(ListBIndex).Left=tPoint.x-2                               ' Fudge (-2) for correct positioning
    ListB(ListBIndex).Top=tPoint.y-2                                ' ditto
    ListB(ListBIndex).AddItems token

    PropertyFieldUpdate("Left",STR$(tPoint.x))                    '
    PropertyFieldUpdate("Top",STR$(tPoint.y))                     ' Update new properties in AddedObjectList..
    PropertyFieldUpdate("Parent",WhichParent(hWnd))               '

    'SaveNewObjDataGrid(hWnd, token, ObjectIndex) '!!! сохранение таблицы
    SaveNewObjDataGrid(hWnd, token, ObjectIndex,tPoint.x, tPoint.y, ListB(ListBIndex).Width, ListB(ListBIndex).Height,ListB(ListBIndex).Color) '!!! сохранение таблицы
    'cmboxObj.addItems token

  else
    ReDrawComponentByField
  end if

END SUB

'*****************************************
SUB AddQGROUPBOX(hWnd AS long)
  call  AddClrString ("5706:parent hWnd="+str$(hWnd), clred, LogEdit)

  'reDIM GrpBox(GrpBoxCount) AS QGROUPBOX

  GrpBoxIndex=GrpBoxCount-1
  inc GrpBoxCount


  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  '!----------------'! new procedure for get parent --------------
  prnt$=GetQParent (hWnd)
  prntName$=field$(prnt$,"_",1)
  call  AddClrString ("5724:prntName$="+(prntName$), clred, LogEdit)
  prntIdx$=field$(prnt$,"_",2)
  call  AddClrString ("5726:prntIdx$="+(prntIdx$), clred, LogEdit)
  prntIndex=val(prntIdx$)

  Select case prntName$
  case "forms"
    GrpBox(GrpBoxIndex).Parent=Forms(prntIndex)
  case "dpan"
    GrpBox(GrpBoxIndex).Parent=dpan(prntIndex)
  case "grpbox"
    GrpBox(GrpBoxIndex).Parent=grpbox(prntIndex)
  case "scrollb"
    GrpBox(GrpBoxIndex).Parent=scrollb(prntIndex)
  case "BoxTab"
    GrpBox(GrpBoxIndex).Parent=BoxTab(prntIndex)

  case else

  end select
  '! -------------------------------------


  ObjectType(ObjectIndex)="QGROUPBOX"
  ObjTypeIndex(ObjectIndex)=GrpBoxIndex
  ObjectHandle(ObjectIndex)=GrpBox(GrpBoxIndex).Handle

  ObjectName(ObjectIndex)="GrpBox"+STR$(GrpBoxIndex) '!========================

  call  AddClrString ("5732:ObjectName("+str$(ObjectIndex)+")="+(ObjectName(ObjectIndex)), clo, LogEdit)
  'call  AddClrString ("5732:token="+(token), clo, LogEdit)

  if flParsed=0 then ' свойства!!!  компонента, если он устанавливается с палитры
    GrpBox(GrpBoxIndex).Width=150
    GrpBox(GrpBoxIndex).Height=100

    token="GrpBox"+STR$(GrpBoxIndex)+_
    " as "+ObjectType(ObjectIndex)+" parent="+_
    ObjectName(ObjParentIdx(ObjectIndex))+" as "+ ObjectType(ObjParentIdx(ObjectIndex))

    GrpBox(GrpBoxIndex).Caption=token

    tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
    ScreenToClient(hWnd,tPoint)
    GrpBox(GrpBoxIndex).Left=tPoint.x
    GrpBox(GrpBoxIndex).Top=tPoint.y
    'ObjectName(ObjectIndex)=token

    PropertyFieldUpdate("Left",STR$(tPoint.x))                    '
    PropertyFieldUpdate("Top",STR$(tPoint.y))                     ' Update new properties in AddedObjectList..
    PropertyFieldUpdate("Caption",token)                          '
    PropertyFieldUpdate("Parent",WhichParent(hWnd))               '

    SaveNewObjDataGrid(hWnd, token, ObjectIndex,tPoint.x, tPoint.y, GrpBox(GrpBoxIndex).Width,_
                       GrpBox(GrpBoxIndex).Height,GrpBox(GrpBoxIndex).color) '!!! сохранение таблицы
    'cmboxObj.addItems token

  else
    ReDrawComponentByField
  end if

  'INC ObjectIndex: INC GrpBoxIndex
END SUB

'*****************************************
' An odd-one-out -> Qpanel placed inside to force scroll bars visible
SUB AddQSCROLLBOX(hWnd AS long)

  reDIM ScrollB(ScrollBCount) AS QSCROLLBOX
  'reDIM BoxInner(ScrollBCount) AS QPANEL

  ScrollBIndex=ScrollBCount-1
  inc ScrollBCount
  ' For effect - force scrollbars visible
  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  'ScrollB(ScrollBIndex).Parent=Forms(FormIndex)                 ' MUST set a valid parent first!
  'IF hWnd<>Forms(FormIndex).Handle THEN
  'SetParent(ScrollB(ScrollBIndex).Handle,hWnd)                ' Set to correct parent
  'END IF

  '!----------------'! new procedure for get parent --------------
  prnt$=GetQParent (hWnd)
  prntName$=field$(prnt$,"_",1)
  call  AddClrString ("5724:prntName$="+(prntName$), clred, LogEdit)
  prntIdx$=field$(prnt$,"_",2)
  call  AddClrString ("5726:prntIdx$="+(prntIdx$), clred, LogEdit)
  prntIndex=val(prntIdx$)

  Select case prntName$
  case "forms"
    ScrollB(ScrollBIndex).Parent=Forms(prntIndex)
  case "dpan"
    ScrollB(ScrollBIndex).Parent=dpan(prntIndex)
  case "grpbox"
    ScrollB(ScrollBIndex).Parent=grpbox(prntIndex)
  case "scrollb"
    ScrollB(ScrollBIndex).Parent=scrollb(prntIndex)
  case "BoxTab"
    ScrollB(ScrollBIndex).Parent=BoxTab(prntIndex)

  case else

  end select
  '! -------------------------------------


  ObjectType(ObjectIndex)="QSCROLLBOX"
  ObjTypeIndex(ObjectIndex)=ScrollBIndex
  ObjectHandle(ObjectIndex)=ScrollB(ScrollBIndex).Handle

  'BoxInner(ScrollBIndex).Parent=ScrollB(ScrollBIndex)
  'BoxInner(ScrollBIndex).Enabled=False                            ' Don't capture mouse clicks!

  if flParsed=0 then ' свойства!!!  компонента, если он устанавливается с палитры
    ScrollB(ScrollBIndex).Width=150                                 ' Force size of ScrollBox
    ScrollB(ScrollBIndex).Height=100
    BoxInner(ScrollBIndex).Width=500                                ' Force scrollbars visible
    BoxInner(ScrollBIndex).Height=500

    token="ScrlBox"+STR$(ScrollBIndex)+" "
    tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
    ScreenToClient(hWnd,tPoint)
    ScrollB(ScrollBIndex).Left=tPoint.x-2                           ' Fudge for correct positioning
    ScrollB(ScrollBIndex).Top=tPoint.y-2                            ' ditto
    ObjectName(ObjectIndex)=token

    'SaveNewObjDataGrid(hWnd, token, ObjectIndex) '!!! сохранение таблицы
    SaveNewObjDataGrid(hWnd, token, ObjectIndex,tPoint.x, tPoint.y, ScrollB(ScrollBIndex).Width, ScrollB(ScrollBIndex).Height,ScrollB(ScrollBIndex).Color) '!!! сохранение таблицы


    'PropertyFieldUpdate("Left",STR$(tPoint.x))                    '
    'PropertyFieldUpdate("Top",STR$(tPoint.y))                     ' Update new properties in AddedObjectList..
    'PropertyFieldUpdate("Parent",WhichParent(hWnd))               '
  else
    ReDrawComponentByField
  end if

  'INC ObjectIndex: INC ScrollBIndex
END SUB

'*****************************************
SUB AddQSCROLLBAR(hWnd AS long)
  reDIM ScrollBar(ScrllBarCount) AS QSCROLLBAR

  ScrllBarIndex=ScrllBarCount-1
  inc ScrllBarCount

  DEFSTR tstr, token
  DIM tPoint AS PointAPI


  fld=GetPropValue ("kind"):if fld>-999 then ScrollBar(ScrllBarIndex).kind=GetPropValue ("kind")

  'ScrollBar(ScrllBarIndex).Parent=Forms(FormIndex)              ' MUST set a valid parent first!

  'IF hWnd<>Forms(FormIndex).Handle THEN
  'SetParent(ScrollBar(ScrllBarIndex).Handle,hWnd)             ' Set to correct parent
  'END IF

  '!----------------'! new procedure for get parent --------------
  prnt$=GetQParent (hWnd)
  prntName$=field$(prnt$,"_",1)
  call  AddClrString ("5724:prntName$="+(prntName$), clred, LogEdit)
  prntIdx$=field$(prnt$,"_",2)
  call  AddClrString ("5726:prntIdx$="+(prntIdx$), clred, LogEdit)
  prntIndex=val(prntIdx$)

  Select case prntName$
  case "forms"
    ScrollBar(ScrllBarIndex).Parent=Forms(prntIndex)
  case "dpan"
    ScrollBar(ScrllBarIndex).Parent=dpan(prntIndex)
  case "grpbox"
    ScrollBar(ScrllBarIndex).Parent=grpbox(prntIndex)
  case "scrollb"
    ScrollBar(ScrllBarIndex).Parent=scrollb(prntIndex)
  case "BoxTab"
    ScrollBar(ScrllBarIndex).Parent=BoxTab(prntIndex)

  case else

  end select
  '! -------------------------------------


  ObjectType(ObjectIndex)="QSCROLLBAR"
  ObjTypeIndex(ObjectIndex)=ScrllBarIndex
  ObjectHandle(ObjectIndex)=ScrollBar(ScrllBarIndex).Handle
  'call  AddClrString ("4858:ScrollBar("+str$(ScrllBarIndex)+"Handle)="+str$(ScrollBar(ScrllBarIndex).Handle), clb, LogEdit)

  if flParsed=0 then ' свойства!!!  компонента, если он устанавливается с палитры

    token="ScrlBar"+STR$(ScrllBarIndex)+" "
    ScrollBar(ScrllBarIndex).Width=100
    ScrollBar(ScrllBarIndex).Height=20
    tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
    ScreenToClient(hWnd,tPoint)
    ScrollBar(ScrllBarIndex).Left=tPoint.x
    ScrollBar(ScrllBarIndex).Top=tPoint.y
    ObjectIndex=ObjectIndex
    ObjectType(ObjectIndex)="QSCROLLBAR"
    ObjTypeIndex(ObjectIndex)=ScrllBarIndex
    ObjectHandle(ObjectIndex)=ScrollBar(ScrllBarIndex).Handle
    ObjectName(ObjectIndex)=token


    PropertyFieldUpdate("Left",STR$(tPoint.x))                    '
    PropertyFieldUpdate("Top",STR$(tPoint.y))                     ' Update new properties in AddedObjectList..
    PropertyFieldUpdate("Parent",WhichParent(hWnd))               '

    'SaveNewObjDataGrid(hWnd, token, ObjectIndex) '!!! сохранение таблицы
    SaveNewObjDataGrid(hWnd, token, ObjectIndex,tPoint.x, tPoint.y, ScrollBar(ScrllBarIndex).Width, _
                       ScrollBar(ScrllBarIndex).Height,0) '!!! сохранение таблицы
  else
    ReDrawComponentByField
  end if

END SUB

'*****************************************
'!!! Arrays of StringGrid has problems - using QListView instead!!
SUB AddQSTRINGGRID(hWnd AS long)
  reDIM StrGrid(StringGCount) as QLISTVIEW

  StringGIndex=StringGCount-1
  inc StringGCount

  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  'StrGrid(StringGIndex).Parent=Forms(FormIndex)                 ' MUST set a valid parent first!
  'IF hWnd<>Forms(FormIndex).Handle THEN
  'SetParent(StrGrid(StringGIndex).Handle,hWnd)                ' Set to correct parent
  'END IF

  '!----------------'! new procedure for get parent --------------
  prnt$=GetQParent (hWnd)
  prntName$=field$(prnt$,"_",1)
  call  AddClrString ("5724:prntName$="+(prntName$), clred, LogEdit)
  prntIdx$=field$(prnt$,"_",2)
  call  AddClrString ("5726:prntIdx$="+(prntIdx$), clred, LogEdit)
  prntIndex=val(prntIdx$)

  Select case prntName$
  case "forms"
    StrGrid(StringGIndex).Parent=Forms(prntIndex)
  case "dpan"
    StrGrid(StringGIndex).Parent=dpan(prntIndex)
  case "grpbox"
    StrGrid(StringGIndex).Parent=grpbox(prntIndex)
  case "scrollb"
    StrGrid(StringGIndex).Parent=scrollb(prntIndex)
  case "BoxTab"
    StrGrid(StringGIndex).Parent=BoxTab(prntIndex)

  case else

  end select
  '! -------------------------------------


  ObjectType(ObjectIndex)="QSTRINGGRID"
  ObjTypeIndex(ObjectIndex)=StringGIndex
  ObjectHandle(ObjectIndex)=StrGrid(StringGIndex).Handle
  'call  AddClrString ("5176:ObjectHandle("+str$(ObjectIndex)+")="+str$(ObjectHandle(ObjectIndex)), clb, LogEdit)

  if flParsed=0 then ' свойства!!!  компонента, если он устанавливается с палитры

    token="StringGrid"+STR$(StringGIndex) +" "
    StrGrid(StringGIndex).Width=150
    StrGrid(StringGIndex).Height=100
    tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
    ScreenToClient(hWnd,tPoint)
    StrGrid(StringGIndex).Left=tPoint.x-2                           ' Fudge to correct positioning
    StrGrid(StringGIndex).Top=tPoint.y-2                            ' ditto


    'StrGrid(StringGIndex).GridLines=True                            '
    'StrGrid(StringGIndex).ViewStyle=vsReport                        ' Some visual presets
    'StrGrid(StringGIndex).AddColumns token,""                       '
    'StrGrid(StringGIndex).Column(0).Width=74
    'StrGrid(StringGIndex).Column(1).Width=74
    ObjectName(ObjectIndex)=token

    PropertyFieldUpdate("Left",STR$(tPoint.x))                    '
    PropertyFieldUpdate("Top",STR$(tPoint.y))                     ' Update new properties in AddedObjectList..
    PropertyFieldUpdate("Parent",WhichParent(hWnd))               '

    'SaveNewObjDataGrid(hWnd, token, ObjectIndex) '!!! сохранение таблицы
    SaveNewObjDataGrid(hWnd, token, ObjectIndex,tPoint.x, tPoint.y, StrGrid(StringGIndex).Width, StrGrid(StringGIndex).Height,StrGrid(StringGIndex).Color) '!!! сохранение таблицы
  else
    ReDrawComponentByField
  end if

END SUB

'*****************************************
SUB AddQLISTVIEW(hWnd AS long)
  reDIM ListView(ListVCount) AS QLISTVIEW

  ListVIndex=ListVCount-1
  inc ListVCount


  DEFSTR tstr, token
  DIM tPoint AS PointAPI


  'ListView(ListVIndex).Parent=Forms(FormIndex)                  ' MUST set a valid parent first!
  'IF 'hWnd<>Forms(FormIndex).Handle THEN
  'SetParent(ListView(ListVIndex).Handle,hWnd)                 ' Set to correct parent
  'END IF

  '!----------------'! new procedure for get parent --------------
  prnt$=GetQParent (hWnd)
  prntName$=field$(prnt$,"_",1)
  call  AddClrString ("5724:prntName$="+(prntName$), clred, LogEdit)
  prntIdx$=field$(prnt$,"_",2)
  call  AddClrString ("5726:prntIdx$="+(prntIdx$), clred, LogEdit)
  prntIndex=val(prntIdx$)

  Select case prntName$
  case "forms"
    ListView(ListVIndex).Parent=Forms(prntIndex)
  case "dpan"
    ListView(ListVIndex).Parent=dpan(prntIndex)
  case "grpbox"
    ListView(ListVIndex).Parent=grpbox(prntIndex)
  case "scrollb"
    ListView(ListVIndex).Parent=scrollb(prntIndex)
  case "BoxTab"
    ListView(ListVIndex).Parent=BoxTab(prntIndex)

  case else

  end select
  '! -------------------------------------

  ObjectType(ObjectIndex)="QLISTVIEW"
  ObjTypeIndex(ObjectIndex)=ListVIndex
  ObjectHandle(ObjectIndex)=ListView(ListVIndex).Handle
  if flParsed=0 then ' свойства!!!  компонента, если он устанавливается с палитры

    token="ListView"+STR$(ListVIndex)+" "
    ListView(ListVIndex).Width=150
    ListView(ListVIndex).Height=100
    tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
    ScreenToClient(hWnd,tPoint)
    ListView(ListVIndex).Left=tPoint.x-2                            ' Fudge fix positioning
    ListView(ListVIndex).Top=tPoint.y-2                             ' ditto

    ListView(ListVIndex).GridLines=True                             '
    ListView(ListVIndex).ViewStyle=vsReport                         ' Some visual presets
    ListView(ListVIndex).AddColumns token,""                        '
    ListView(ListVIndex).Column(0).Width=74
    ListView(ListVIndex).Column(1).Width=74
    ObjectName(ObjectIndex)=token

    PropertyFieldUpdate("Left",STR$(tPoint.x))                    '
    PropertyFieldUpdate("Top",STR$(tPoint.y))                     ' Update new properties in AddedObjectList..
    PropertyFieldUpdate("Parent",WhichParent(hWnd))               '

    'SaveNewObjDataGrid(hWnd, token, ObjectIndex) '!!! сохранение таблицы
    SaveNewObjDataGrid(hWnd, token, ObjectIndex,tPoint.x, tPoint.y, ListView(ListVIndex).Width, ListView(ListVIndex).Height,ListView(ListVIndex).Color) '!!! сохранение таблицы
  else
    ReDrawComponentByField
  end if

  'INC ObjectIndex: INC ListVIndex
END SUB

'*****************************************
' Problems with this so using a QPANEL container
SUB AddQHEADER(hWnd AS long)

  reDIM Headr(HeadCount) AS QHEADER
  reDIM BoxHeadr(HeadCount) AS QPANEL

  HeadIndex=HeadCount-1
  inc HeadCount



  DEFSTR tstr, token
  DIM rect AS QRECT
  DIM tPoint AS PointAPI

  IF ParentHasObject(hWnd,NewObjectID,"QHEADER") THEN EXIT SUB   ' ONLY 1 object per parent allowed!


  'BoxHeadr(HeadIndex).Parent=Forms(FormIndex)                   ' MUST set a valid parent first!
  'IF hWnd<>Forms(FormIndex).Handle THEN
  'SetParent(BoxHeadr(HeadIndex).Handle,hWnd)                  ' Set to correct parent
  'END IF

  '!----------------'! new procedure for get parent --------------
  prnt$=GetQParent (hWnd)
  prntName$=field$(prnt$,"_",1)
  call  AddClrString ("5724:prntName$="+(prntName$), clred, LogEdit)
  prntIdx$=field$(prnt$,"_",2)
  call  AddClrString ("5726:prntIdx$="+(prntIdx$), clred, LogEdit)
  prntIndex=val(prntIdx$)

  Select case prntName$
  case "forms"
    BoxHeadr(HeadIndex).Parent=Forms(prntIndex)
  case "dpan"
    BoxHeadr(HeadIndex).Parent=dpan(prntIndex)
  case "grpbox"
    BoxHeadr(HeadIndex).Parent=grpbox(prntIndex)
  case "scrollb"
    BoxHeadr(HeadIndex).Parent=scrollb(prntIndex)
  case "BoxTab"
    BoxHeadr(HeadIndex).Parent=BoxTab(prntIndex)

  case else

  end select
  '! -------------------------------------


  Headr(HeadIndex).Parent=BoxHeadr(HeadIndex)
  Headr(HeadIndex).Align=alClient
  Headr(HeadIndex).AddSections "Hdr1","Hdr2","Hdr3"
  Headr(HeadIndex).Enabled=False

  ObjectType(ObjectIndex)="QHEADER"
  ObjTypeIndex(ObjectIndex)=HeadIndex
  ObjectHandle(ObjectIndex)=BoxHeadr(HeadIndex).Handle

  if flParsed=0 then ' свойства!!!  компонента, если он устанавливается с палитры


    token="Header"+STR$(HeadIndex)+" "
    BoxHeadr(HeadIndex).Align=alTop
    BoxHeadr(HeadIndex).Height=17
    BoxHeadr(HeadIndex).BevelOuter=2
    ObjectName(ObjectIndex)=token


    PropertyFieldUpdate("Parent",WhichParent(hWnd))
    'SaveNewObjDataGrid(hWnd, token, ObjectIndex) '!!! сохранение таблицы

    SaveNewObjDataGrid(hWnd, token, ObjectIndex,tPoint.x, tPoint.y, BoxHeadr(HeadIndex).Width, BoxHeadr(HeadIndex).Height,BoxHeadr(HeadIndex).Color) '!!! сохранение таблицы
  else
    ReDrawComponentByField
  end if

  'INC ObjectIndex: INC HeadIndex
END SUB

'*****************************************
SUB AddQSTATUSBAR(hWnd AS long)

  reDIM StatBar(StatCount) AS QSTATUSBAR
  reDIM BoxStat(StatCount) AS QPANEL

  StatIndex=StatCount-1
  inc StatCount


  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  'IF ParentHasObject(hWnd,NewObjectID) THEN EXIT SUB              ' ONLY 1 object per parent allowed!
  '!!! Allowed!!!


  'BoxStat(StatIndex).Parent=Forms(FormIndex)                    ' MUST set a valid parent first!
  'IF hWnd<>Forms(FormIndex).Handle THEN
  'SetParent(BoxStat(StatIndex).Handle,hWnd)                   ' Set to correct parent
  'END IF


  '!----------------'! new procedure for get parent --------------
  prnt$=GetQParent (hWnd)
  prntName$=field$(prnt$,"_",1)
  call  AddClrString ("5724:prntName$="+(prntName$), clred, LogEdit)
  prntIdx$=field$(prnt$,"_",2)
  call  AddClrString ("5726:prntIdx$="+(prntIdx$), clred, LogEdit)
  prntIndex=val(prntIdx$)

  Select case prntName$
  case "forms"
    BoxStat(StatIndex).Parent=Forms(prntIndex)
  case "dpan"
    BoxStat(StatIndex).Parent=dpan(prntIndex)
  case "grpbox"
    BoxStat(StatIndex).Parent=grpbox(prntIndex)
  case "scrollb"
    BoxStat(StatIndex).Parent=scrollb(prntIndex)
  case "BoxTab"
    BoxStat(StatIndex).Parent=BoxTab(prntIndex)

  case else

  end select
  '! -------------------------------------

  StatBar(StatIndex).Parent=BoxStat(StatIndex)

  BoxStat(StatIndex).Align=alBottom
  BoxStat(StatIndex).Height=19
  BoxStat(StatIndex).color=clb
  StatBar(StatIndex).Align=alClient
  StatBar(StatIndex).SimplePanel=True

  ObjectType(ObjectIndex)="QSTATUSBAR"
  ObjTypeIndex(ObjectIndex)=StatIndex
  ObjectHandle(ObjectIndex)=BoxStat(StatIndex).Handle

  'BoxStat(StatIndex).BevelOuter=2
  StatBar(StatIndex).SimpleText=token
  StatBar(StatIndex).Enabled=False


  if flParsed=0 then ' свойства!!!  компонента, если он устанавливается с палитры

    token="Status"+STR$(StatIndex)+" "

    ObjectName(ObjectIndex)=token

    PropertyFieldUpdate("Parent",WhichParent(hWnd))

    'SaveNewObjDataGrid(hWnd, token, ObjectIndex) '!!! сохранение таблицы
    SaveNewObjDataGrid(hWnd, token, ObjectIndex,tPoint.x, tPoint.y, BoxStat(StatIndex).Width, BoxStat(StatIndex).Height,BoxStat(StatIndex).Color) '!!! сохранение таблицы
  else
    ReDrawComponentByField
  end if

  'INC ObjectIndex: INC StatIndex
END SUB

'*****************************************
SUB AddQDIRTREE(hWnd AS long)
  'reDIM DirTree(DirTIndex+1) AS QDIRTREE

  reDIM BoxDTree(DirTCount) AS QPANEL

  DirTIndex=DirTCount-1
  inc DirTCount


  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  IF DirTIndex>8 THEN                                             ' ONLY 1 allowed!
    MessageBox("Internally limited to 8 instance only!","RapidFRM "+VER,&h30)
    EXIT SUB
  END IF

  'BoxDTree(DirTIndex).BevelOuter=2
  'BoxDTree(DirTIndex).Parent=Forms(FormIndex)                              ' MUST set a valid parent first!
  'IF hWnd<>Forms(FormIndex).Handle THEN
  'SetParent(BoxDTree(DirTIndex).Handle,hWnd)                             ' Set to correct parent
  'END IF

  '!----------------'! new procedure for get parent --------------
  prnt$=GetQParent (hWnd)
  prntName$=field$(prnt$,"_",1)
  call  AddClrString ("5724:prntName$="+(prntName$), clred, LogEdit)
  prntIdx$=field$(prnt$,"_",2)
  call  AddClrString ("5726:prntIdx$="+(prntIdx$), clred, LogEdit)
  prntIndex=val(prntIdx$)

  Select case prntName$
  case "forms"
    BoxDTree(DirTIndex).Parent=Forms(prntIndex)
  case "dpan"
    BoxDTree(DirTIndex).Parent=dpan(prntIndex)
  case "grpbox"
    BoxDTree(DirTIndex).Parent=grpbox(prntIndex)
  case "scrollb"
    BoxDTree(DirTIndex).Parent=scrollb(prntIndex)
  case "BoxTab"
    BoxDTree(DirTIndex).Parent=BoxTab(prntIndex)

  case else

  end select
  '! -------------------------------------


  'call  AddClrString ("5376:DirTIndex="+str$(DirTIndex), clred, LogEdit)

  Select case DirTIndex
  case 0
    DirTree0.Parent=BoxDTree(DirTIndex): DirTree0.Align=alClient: DirTree0.Enabled=False
  case 1
    DirTree1.Parent=BoxDTree(DirTIndex): DirTree1.Align=alClient: DirTree1.Enabled=False
  case 2
    DirTree2.Parent=BoxDTree(DirTIndex): DirTree2.Align=alClient: DirTree2.Enabled=False
  case 3
    DirTree3.Parent=BoxDTree(DirTIndex): DirTree3.Align=alClient: DirTree3.Enabled=False
  case 4
    DirTree4.Parent=BoxDTree(DirTIndex): DirTree4.Align=alClient: DirTree4.Enabled=False
  case 5
    DirTree5.Parent=BoxDTree(DirTIndex): DirTree5.Align=alClient: DirTree5.Enabled=False
  case 6
    DirTree6.Parent=BoxDTree(DirTIndex): DirTree6.Align=alClient: DirTree6.Enabled=False
  case 7
    DirTree7.Parent=BoxDTree(DirTIndex): DirTree7.Align=alClient: DirTree7.Enabled=False

  case else
    DirTree0.Parent=BoxDTree(DirTIndex): DirTree0.Align=alClient: DirTree0.Enabled=False
  end select


  ObjectType(ObjectIndex)="QDIRTREE"
  call  AddClrString ("9076:ObjectType("+str$(ObjectIndex)+")="+str$(ObjectType(ObjectIndex)), clred, LogEdit)
  ObjTypeIndex(ObjectIndex)=DirTIndex
  call  AddClrString ("9078:ObjTypeIndex("+str$(ObjectIndex)+")="+str$(ObjTypeIndex(ObjectIndex)), clred, LogEdit)
  ObjectHandle(ObjectIndex)=BoxDTree(DirTIndex).Handle
  call  AddClrString ("9080:ObjectHandle("+str$(ObjectIndex)+")="+str$(ObjectHandle(ObjectIndex)), clred, LogEdit)

  if flParsed=0 then ' свойства!!!  компонента, если он устанавливается с палитры

    token="DirTree"+STR$(DirTIndex)+" "
    BoxDTree(DirTIndex).Width=150
    BoxDTree(DirTIndex).Height=150
    tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
    ScreenToClient(hWnd,tPoint)
    BoxDTree(DirTIndex).Left=tPoint.x: BoxDTree(DirTIndex).Top=tPoint.y

    ObjectName(ObjectIndex)=token

    PropertyFieldUpdate("Left",STR$(tPoint.x))

    'SaveNewObjDataGrid(hWnd, token, ObjectIndex) '!!! сохранение таблицы
    SaveNewObjDataGrid(hWnd, token, ObjectIndex,tPoint.x, tPoint.y, BoxDTree(DirTIndex).Width, BoxDTree(DirTIndex).Height,BoxDTree(DirTIndex).Color) '!!! сохранение таблицы
  else
    ReDrawComponentByField


    Select case DirTIndex
    case 0
      DirTree0.Color=BoxDTree(DirTIndex).Color:
    case 1
      DirTree1.Color=BoxDTree(DirTIndex).Color:
    case 2
      DirTree2.Color=BoxDTree(DirTIndex).Color:
    case 3
      DirTree3.Color=BoxDTree(DirTIndex).Color:
    case 4
      DirTree4.Color=BoxDTree(DirTIndex).Color:
    case 5
      DirTree5.Color=BoxDTree(DirTIndex).Color:
    case 6
      DirTree6.Color=BoxDTree(DirTIndex).Color:
    case 7
      DirTree7.Color=BoxDTree(DirTIndex).Color:

    case else
      DirTree0.Color=BoxDTree(DirTIndex).Color:
    end select


  end if

  'INC ObjectIndex: INC DirTIndex
End Sub


'*****************************************
SUB AddQSPLITTER(hWnd AS long)       ' не используется!                               ' Fudge using a QPanel

  reDIM panSplit(SplitCount) AS QPANEL
  SplitIndex=SplitCount-1
  inc SplitCount


  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  hWnd=Forms(FormIndex).Handle                                  ' FORCE to FormIndex!
  'IF ParentHasObject(hWnd,NewObjectID) THEN EXIT SUB              ' ONLY 1 object parent allowed!

  token="Split"+STR$(SplitIndex)+" "
  panSplit(SplitIndex).Parent=Forms(FormIndex)                  ' Set parent property to form
  tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
  ScreenToClient(hWnd,tPoint)
  panSplit(SplitIndex).Left=tPoint.x
  panSplit(SplitIndex).Top=0
  panSplit(SplitIndex).Height=Forms(FormIndex).ClientHeight
  panSplit(SplitIndex).Width=3
  panSplit(SplitIndex).BorderStyle=1
  panSplit(SplitIndex).Cursor=crHSplit

  'tstr=STR$(NewObjectID)+"|QSPLITTER|"+STR$(panSplit(SplitIndex).Handle)+"|"+token+"|"+token+"|"+STR$(hWnd)+"~"
  'AddedObjectList(ObjectIndex)=tstr+GetDefaultProperties(NewObjectID)

  PropertyFieldUpdate("Left",STR$(tPoint.x))                    '
  PropertyFieldUpdate("Top","0")                                ' Update new properties in AddedObjectList..
  PropertyFieldUpdate("Width","3")                              '
  PropertyFieldUpdate("Height",STR$(Forms(FormIndex).ClientHeight))    '
  PropertyFieldUpdate("Parent",WhichParent(hWnd))               '

  !!! 'cmboxObj.AddItems token +" [QSPLITTER]"
  !!! 'cmboxObj.ItemIndex=ObjectIndex
  'cmboxObjOnChange
  'UpdatePropGrid(ObjectIndex)                                   ' Update String grid

  SaveNewObjDataGrid(hWnd, token, ObjectIndex,tPoint.x, tPoint.y, panSplit(SplitIndex).Width, panSplit(SplitIndex).Height,panSplit(SplitIndex).Color) '!!! сохранение таблицы

  'INC ObjectCount: INC SplitIndex
END SUB

' Non-visible components
'*****************************************
SUB AddNonVisible(hWnd AS long)
  DIM dNonVis(NonVIndex+1) AS QBUTTON
  DEFINT i, ObjIdx
  DEFSTR tstr, ObjType, ObjName

  SELECT CASE NewObjectID
  CASE Q_BITMAP
    INC BmpIndex: ObjIdx=BmpIndex
    ObjName="Bitmap"+STR$(ObjIdx): ObjType="QBITMAP"
  CASE Q_IMAGELIST
    INC ImgListIndex: ObjIdx=ImgListIndex
    ObjName="ImageList"+STR$(ObjIdx): ObjType="QIMAGELIST"
  CASE Q_STRINGLIST
    INC StrListIndex: ObjIdx=StrListIndex
    ObjName="StringList"+STR$(ObjIdx): ObjType="QSTRINGLIST"
  CASE Q_TIMER
    INC TimerIndex: ObjIdx=TimerIndex
    ObjName="Timer"+STR$(ObjIdx): ObjType="QTIMER"
  CASE Q_SOCKET
    INC SockIndex: ObjIdx=SockIndex
    ObjName="Socket"+STR$(ObjIdx): ObjType="QSOCKET"
  CASE Q_FILESTREAM
    INC FStreamIndex: ObjIdx=FStreamIndex
    ObjName="FileStream"+STR$(ObjIdx): ObjType="QFILESTREAM"
  CASE Q_MEMORYSTREAM
    INC MStreamIndex: ObjIdx=MStreamIndex
    ObjName="MemStream"+STR$(ObjIdx): ObjType="QMEMORYSTREAM"
  CASE Q_FONT
    INC FontIndex: ObjIdx=FontIndex
    ObjName="Font"+STR$(ObjIdx): ObjType="QFONT"
  CASE Q_MYSQL
    INC SQLIndex: ObjIdx=SQLIndex
    ObjName="MySQL"+STR$(ObjIdx): ObjType="QMYSQL"
  CASE Q_OLEOBJECT
    INC OleObjIndex: ObjIdx=OleObjIndex
    ObjName="OLEObject"+STR$(ObjIdx): ObjType="QOLEOBJECT"
  CASE Q_REGISTRY
    INC RegIndex: ObjIdx=RegIndex
    ObjName="Registry"+STR$(ObjIdx): ObjType="QREGISTRY"
  CASE Q_OPENDIALOG
    '            IF OpenDlgIndex>0 THEN EXIT SUB                            ' One instance only?
    INC OpenDlgIndex: ObjIdx=OpenDlgIndex
    ObjName="OpenDialog"+STR$(ObjIdx): ObjType="QOPENDIALOG"
  CASE Q_SAVEDIALOG
    '            IF SaveDlgIndex>0 THEN EXIT SUB
    INC SaveDlgIndex: ObjIdx=SaveDlgIndex
    ObjName="SaveDialog"+STR$(ObjIdx): ObjType="QSAVEDIALOG"
  CASE Q_FONTDIALOG
    '            IF FontDlgIndex>0 THEN EXIT SUB
    INC FontDlgIndex: ObjIdx=FontDlgIndex
    ObjName="FontDialog"+STR$(ObjIdx): ObjType="QFONTDIALOG"
  CASE Q_COLORDIALOG
    '            IF ColorDlgIndex>0 THEN EXIT SUB
    INC ColorDlgIndex: ObjIdx=ColorDlgIndex
    ObjName="ColorDialog"+STR$(ObjIdx): ObjType="QCOLORDIALOG"
  CASE Q_DXTIMER
    '            IF DXTimerIdx>0 THEN EXIT SUB
    INC DXTimerIdx: ObjIdx=DXTimerIdx
    ObjName="DXTimer"+STR$(ObjIdx): ObjType="QDXTIMER"
  CASE Q_DXSOUND
    '            IF DXSoundIdx>0 THEN EXIT SUB
    INC DXSoundIdx: ObjIdx=DXSoundIdx
    ObjName="DXSound"+STR$(ObjIdx): ObjType="QDXSOUND"
  CASE Q_DXSCREEN
    '            IF DXScreenIdx>0 THEN EXIT SUB
    INC DXScreenIdx: ObjIdx=DXScreenIdx
    ObjName="DXScreen"+STR$(ObjIdx): ObjType="QDXSCREEN"
  CASE Q_DXIMAGELIST
    '            IF DXImgListIdx>0 THEN EXIT SUB
    INC DXImgListIdx: ObjIdx=DXImgListIdx
    ObjName="DXImgList"+STR$(ObjIdx): ObjType="QDXIMAGELIST"
  CASE Q_D3DFACE
    '            IF D3DFaceIdx>0 THEN EXIT SUB
    INC D3DFaceIdx: ObjIdx=D3DFaceIdx
    ObjName="D3DFace"+STR$(ObjIdx): ObjType="QD3DFACE"
  CASE Q_D3DMESHBUILDER
    '            IF MeshBuilderIdx>0 THEN EXIT SUB
    INC MeshBuilderIdx: ObjIdx=MeshBuilderIdx
    ObjName="MeshBuilder"+STR$(ObjIdx): ObjType="QD3DMESHBUILDER"
  CASE Q_D3DFRAME
    '            IF D3DFrameIdx>0 THEN EXIT SUB
    INC D3DFrameIdx: ObjIdx=D3DFrameIdx
    ObjName="D3DFrame"+STR$(ObjIdx): ObjType="QD3DFRAME"
  CASE Q_D3DLIGHT
    '            IF D3DLightIdx>0 THEN EXIT SUB
    INC D3DLightIdx: ObjIdx=D3DLightIdx
    ObjName="D3DLight"+STR$(ObjIdx): ObjType="QD3DLIGHT"
  CASE Q_D3DTEXTURE
    '            IF TextureIdx>0 THEN EXIT SUB
    INC TextureIdx: ObjIdx=TextureIdx
    ObjName="D3DTexture"+STR$(ObjIdx): ObjType="QD3DTEXTURE"
  CASE Q_D3DVECTOR
    '            IF VectorIdx>0 THEN EXIT SUB
    INC VectorIdx: ObjIdx=VectorIdx
    ObjName="D3DVector"+STR$(ObjIdx): ObjType="QD3DVECTOR"
  CASE Q_D3DWRAP
    '            IF D3DWrapIdx>0 THEN EXIT SUB
    INC D3DWrapIdx: ObjIdx=D3DWrapIdx
    ObjName="D3DWrap"+STR$(ObjIdx): ObjType="QD3DWRAP"
  CASE ELSE
    EXIT SUB
  END SELECT

  dNonVis(NonVIndex).Parent=NonVisPanel
  dNonVis(NonVIndex).Left=NonVisCount*32 + 5                      ' Position the button
  dNonVis(NonVIndex).Top=16
  dNonVis(NonVIndex).Width=30
  dNonVis(NonVIndex).Height=30
  dNonVis(NonVIndex).Hint=ObjName                                 ' Current component name
  dNonVis(NonVIndex).ShowHint=True
  dNonVis(NonVIndex).BMP=NonVisBMP.BMP                            ' Copy the bitmap image
  ObjectIndex=ObjectIndex

  'tstr=STR$(NewObjectID)+"|"+ObjType+"|"+STR$(dNonVis(NonVIndex).Handle)+"|"+ObjName+"|"+ObjName+"|0~"
  'AddedObjectList(ObjectIndex)=tstr+GetDefaultProperties(NewObjectID)

  !!! cmboxObj.AddItems ObjName+" ["+ObjType+"]"
  cmboxObj.ItemIndex=ObjectIndex
  ' cmboxObjOnChange
  UpdatePropGrid(ObjectIndex)                                   ' Update String grid
  INC ObjectCount: INC NonVIndex: INC NonVisCount
END SUB


'*****************************************
SUB AddQFILELISTBOX(hWnd AS long)
  reDIM dFileL(FileLCount) AS QFILELISTBOX
  reDIM BoxFile(FileLCount) AS QPANEL

  FileLindex=FileLCount-1
  inc FileLCount

  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  'BoxFile(FileLindex).Parent=Forms(FormIndex)                   ' MUST set a valid parent first!
  'IF hWnd<>Forms(FormIndex).Handle THEN
  'SetParent(BoxFile(FileLindex).Handle,hWnd)                  ' Set to correct parent
  'END IF

  '!----------------'! new procedure for get parent --------------
  prnt$=GetQParent (hWnd)
  prntName$=field$(prnt$,"_",1)
  call  AddClrString ("5724:prntName$="+(prntName$), clred, LogEdit)
  prntIdx$=field$(prnt$,"_",2)
  call  AddClrString ("5726:prntIdx$="+(prntIdx$), clred, LogEdit)
  prntIndex=val(prntIdx$)

  Select case prntName$
  case "forms"
    BoxFile(FileLIndex).Parent=Forms(prntIndex)
  case "dpan"
    BoxFile(FileLIndex).Parent=dpan(prntIndex)
  case "grpbox"
    BoxFile(FileLIndex).Parent=grpbox(prntIndex)
  case "scrollb"
    BoxFile(FileLIndex).Parent=scrollb(prntIndex)
  case "BoxTab"
    BoxFile(FileLIndex).Parent=BoxTab(prntIndex)

  case else

  end select
  '! -------------------------------------



  BoxFile(FileLindex).height=100
  dFileL(FileLindex).Parent=BoxFile(FileLindex)
  dFileL(FileLindex).Align=alClient
  dFileL(FileLindex).Enabled=False
  ObjectIndex=ObjectIndex

  ObjectType(ObjectIndex)="QFILELISTBOX"
  ObjTypeIndex(ObjectIndex)=FileLindex
  ObjectHandle(ObjectIndex)=BoxFile(FileLindex).Handle




  if flParsed=0 then ' свойства!!!  компонента, если он устанавливается с палитры
    token="FileListBox"+ STR$(FileLindex)+" "
    BoxFile(FileLindex).Width=150
    BoxFile(FileLindex).Height=150
    BoxFile(FileLindex).BevelOuter=2

    tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
    ScreenToClient(hWnd,tPoint)
    BoxFile(FileLindex).Left=tPoint.x
    BoxFile(FileLindex).Top=tPoint.y
    ObjectName(ObjectIndex)=token


    SaveNewObjDataGrid(hWnd, token, ObjectIndex,tPoint.x, tPoint.y, BoxFile(FileLindex).Width, BoxFile(FileLindex).Height,BoxFile(FileLindex).Color) '!!! сохранение таблицы
  else
    ReDrawComponentByField
  end if

END SUB

'*****************************************
SUB AddQGAUGE(hWnd AS long)                                         ' Fudge using QPANEL
  'call  AddClrString ("5739:AddQGAUGE("+str$(hWnd AS long), subclr, LogEdit)
  reDIM dGauge(GaugeCount) AS QGAUGE
  reDIM panGauge(GaugeCount) AS QPANEL

  Gaugeindex=GaugeCount-1
  inc GaugeCount

  DEFSTR tstr, token
  DIM tPoint AS PointAPI


  'panGauge(GaugeIndex).BevelOuter=2
  'panGauge(GaugeIndex).Parent=Forms(FormIndex)                  ' MUST set a valid parent first!
  'IF hWnd<>Forms(FormIndex).Handle THEN
  'SetParent(panGauge(GaugeIndex).Handle,hWnd)                 ' Set to correct parent
  'END IF

  '!----------------'! new procedure for get parent --------------
  prnt$=GetQParent (hWnd)
  prntName$=field$(prnt$,"_",1)
  call  AddClrString ("5724:prntName$="+(prntName$), clred, LogEdit)
  prntIdx$=field$(prnt$,"_",2)
  call  AddClrString ("5726:prntIdx$="+(prntIdx$), clred, LogEdit)
  prntIndex=val(prntIdx$)

  Select case prntName$
  case "forms"
    panGauge(GaugeIndex).Parent=Forms(prntIndex)
  case "dpan"
    panGauge(GaugeIndex).Parent=dpan(prntIndex)
  case "grpbox"
    panGauge(GaugeIndex).Parent=grpbox(prntIndex)
  case "scrollb"
    panGauge(GaugeIndex).Parent=scrollb(prntIndex)
  case "BoxTab"
    panGauge(GaugeIndex).Parent=BoxTab(prntIndex)

  case else

  end select
  '! -------------------------------------

  dGauge(GaugeIndex).Parent=panGauge(GaugeIndex)
  dGauge(GaugeIndex).Align=alClient

  ObjectType(ObjectIndex)="QGAUGE"
  ObjTypeIndex(ObjectIndex)=GaugeIndex
  ObjectHandle(ObjectIndex)=panGauge(GaugeIndex).Handle
  ''call  AddClrString ("5762:flParsed="+str$(flParsed), clb, LogEdit)

  if flParsed=0 then ' свойства!!!  компонента, если он устанавливается с палитры

    token="Gauge"+STR$(GaugeIndex)+" "
    panGauge(GaugeIndex).Width=100
    panGauge(GaugeIndex).Height=25
    dGauge(GaugeIndex).Position=75

    tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
    ScreenToClient(hWnd,tPoint)
    panGauge(GaugeIndex).Left=tPoint.x
    panGauge(GaugeIndex).Top=tPoint.y
    ObjectName(ObjectIndex)=token


    SaveNewObjDataGrid(hWnd, token, ObjectIndex,tPoint.x, tPoint.y, panGauge(GaugeIndex).Width, _
                       panGauge(GaugeIndex).Height,panGauge(GaugeIndex).Color) '!!! сохранение таблицы
  else
    ReDrawComponentByField
  end if

  'INC ObjectIndex: INC GaugeIndex
END SUB

'*****************************************
SUB AddQMenuItem(hWnd AS long)
  'call  AddClrString ("5953:AddQMenuItem hWnd="+str$(hWnd), subclr, LogEdit)
  'dim MnuItem(256) AS QMenuItem
  'DEFINT MainMnuIdx
  'defint MnuItemIdx

  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  ParentObjIdx=ObjParentIdx(ObjectIndex)
  ParentObjType$=ObjectType(ParentObjIdx)

  'call  AddClrString ("5973:FormIndex="+str$(FormIndex), cldb, LogEdit)
  'call  AddClrString ("5966:MainMnuIdx="+str$(MainMnuIdx), clb, LogEdit)
  'call  AddClrString ("5967:MnuItemIdx="+str$(MnuItemIdx), clb, LogEdit)
  'call  AddClrString ("5968:ObjParentIdx("+str$(ObjectIndex)+")="+str$(ObjParentIdx(ObjectIndex)), clb, LogEdit)

  MnuItem(MnuItemIdx).caption=GetPropString("caption")-qt

  'call  AddClrString ("5972:MnuItem("+str$(MnuItemIdx)+")caption)="+(MnuItem(MnuItemIdx).caption), cldb, LogEdit)

  'call  AddClrString ("5975:ObjectIndex="+str$(ObjectIndex), clp, LogEdit)

  'call  AddClrString ("5975:Parent ObjectType("+str$(ObjParentIdx(ObjectIndex))+")="+_
  'ParentObjType$, clp, LogEdit)

  Select case MainMnuIdx-1 'оно всего одно на форму
  case 0
    'call  AddClrString ("5985:MnuItem("+str$(ParentObjIdx)+")caption)="+(MnuItem(ParentObjIdx).caption), clo, LogEdit)
    'call  AddClrString ("5986:ParentObjType$="+(ParentObjType$), clo, LogEdit)

    if ParentObjType$="QMAINMENU" then
      MainMnu0.AddItems MnuItem(MnuItemIdx)
    elseif ParentObjType$="QMENUITEM" then
      MnuItem(ObjTypeIndex(ParentObjIdx)).AddItems MnuItem(MnuItemIdx)
    end if


    'ObjectHandle(ObjectIndex)=MainMnu0.Handle

  case 1
    MainMnu1.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu1.Handle
  case 2
    MainMnu2.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu2.Handle
  case 3
    MainMnu3.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu3.Handle
  case 4
    MainMnu4.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu4.Handle
  case 5
    MainMnu5.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu5.Handle
  case 6
    MainMnu6.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu6.Handle
  case 7
    MainMnu7.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu7.Handle
  case 8
    MainMnu8.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu8.Handle
  case 9
    MainMnu9.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu9.Handle
  case 10
    MainMnu10.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu10.Handle
  case 11
    MainMnu11.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu11.Handle
  case 12
    MainMnu12.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu12.Handle
  case 13
    MainMnu13.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu13.Handle
  case 14
    MainMnu14.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu14.Handle
  case 15
    MainMnu15.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu15.Handle

  case else
    'ShowMessage ("6012:AddQMainMenu MainMnuIdx out of range-"+str$(MainMnuIdx))
    'call  AddClrString ("6044:AddQMenuItem MainMnuIdx out of range="+str$(MainMnuIdx), clred, LogEdit)

  end select


  ObjectIndex=ObjectIndex

  ObjectType(ObjectIndex)="QMENUITEM"
  ObjTypeIndex(ObjectIndex)=MnuItemIdx
  ObjectName(ObjectIndex)=token

  if flParsed=0 then ' свойства!!!  компонента, если он устанавливается с палитры
    token="MainMnu"+STR$(MnuItemIdx+1)
    'SaveNewObjDataGrid(hWnd, token, ObjectIndex,tPoint.x, tPoint.y, dTrackBar(TrackBIndex).Width, _
    'dTrackBar(TrackBIndex).Height,Color) '!!! сохранение таблицы
  else
    'ReDrawComponentByField
  end if

  INC ObjectIndex: INC MnuItemIdx
END SUB



'*****************************************
SUB AddQMainMenu(hWnd AS long)
  'call  AddClrString ("5953:AddQMainMenu hWnd="+str$(hWnd), subclr, LogEdit)
  'reDIM MainMnu(MainMnuIdx+1) AS QMainMnu
  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  'call  AddClrString ("5959:MainMnuIdx="+str$(MainMnuIdx), clred, LogEdit)

  Select case MainMnuIdx
  case 0
    MainMnu0.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu0.Handle
    'call  AddClrString ("5964:MainMnu0.Handle="+str$(MainMnu0.Handle), clb, LogEdit)

  case 1
    MainMnu1.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu1.Handle
  case 2
    MainMnu2.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu2.Handle
  case 3
    MainMnu3.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu3.Handle
  case 4
    MainMnu4.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu4.Handle
  case 5
    MainMnu5.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu5.Handle
  case 6
    MainMnu6.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu6.Handle
  case 7
    MainMnu7.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu7.Handle
  case 8
    MainMnu8.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu8.Handle
  case 9
    MainMnu9.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu9.Handle
  case 10
    MainMnu10.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu10.Handle
  case 11
    MainMnu11.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu11.Handle
  case 12
    MainMnu12.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu12.Handle
  case 13
    MainMnu13.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu13.Handle
  case 14
    MainMnu14.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu14.Handle
  case 15
    MainMnu15.Parent=Forms(FormIndex)                ' MUST set a valid parent first!
    ObjectHandle(ObjectIndex)=MainMnu15.Handle

  case else
    'ShowMessage ("6012:AddQMainMenu MainMnuIdx out of range-"+str$(MainMnuIdx))
    'call  AddClrString ("6132::AddQMainMenu MainMnuIdx out of range="+str$(MainMnuIdx), clred, LogEdit)

  end select


  ObjectIndex=ObjectIndex

  ObjectType(ObjectIndex)="QMAINMENU"
  ObjTypeIndex(ObjectIndex)=MainMnuIdx
  ObjectName(ObjectIndex)=token

  if flParsed=0 then ' свойства!!!  компонента, если он устанавливается с палитры
    token="MainMnu"+STR$(MainMnuIdx+1)
    'SaveNewObjDataGrid(hWnd, token, ObjectIndex,tPoint.x, tPoint.y, dTrackBar(TrackBIndex).Width, _
    'dTrackBar(TrackBIndex).Height,Color) '!!! сохранение таблицы
  else
    'ReDrawComponentByField
  end if

  INC ObjectIndex: INC MainMnuIdx
END SUB


'*****************************************
SUB AddQTRACKBAR(hWnd AS long)
  reDIM dTrackBar(TrackBCount) AS QTRACKBAR


  TrackBindex=TrackBCount-1
  inc TrackBCount


  DEFSTR tstr, token
  DIM tPoint AS PointAPI


  'dTrackBar(TrackBIndex).Parent=Forms(FormIndex)                ' MUST set a valid parent first!
  'IF hWnd<>Forms(FormIndex).Handle THEN
  'SetParent(dTrackBar(TrackBIndex).Handle,hWnd)               ' Set to correct parent
  'END IF

  '!----------------'! new procedure for get parent --------------
  prnt$=GetQParent (hWnd)
  prntName$=field$(prnt$,"_",1)
  call  AddClrString ("5724:prntName$="+(prntName$), clred, LogEdit)
  prntIdx$=field$(prnt$,"_",2)
  call  AddClrString ("5726:prntIdx$="+(prntIdx$), clred, LogEdit)
  prntIndex=val(prntIdx$)

  Select case prntName$
  case "forms"
    dTrackBar(TrackBIndex).Parent=Forms(prntIndex)
  case "dpan"
    dTrackBar(TrackBIndex).Parent=dpan(prntIndex)
  case "grpbox"
    dTrackBar(TrackBIndex).Parent=grpbox(prntIndex)
  case "scrollb"
    dTrackBar(TrackBIndex).Parent=scrollb(prntIndex)
  case "BoxTab"
    dTrackBar(TrackBIndex).Parent=BoxTab(prntIndex)

  case else

  end select
  '! -------------------------------------


  dTrackBar(TrackBIndex).Position=15

  ObjectType(ObjectIndex)="QTRACKBAR"
  ObjTypeIndex(ObjectIndex)=TrackBIndex
  ObjectHandle(ObjectIndex)=dTrackBar(TrackBIndex).Handle
  ObjectName(ObjectIndex)=token

  if flParsed=0 then ' свойства!!!  компонента, если он устанавливается с палитры

    token="TrackBar"+STR$(TrackBIndex)+" "
    dTrackBar(TrackBIndex).Width=150
    dTrackBar(TrackBIndex).Height=45
    tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
    ScreenToClient(hWnd,tPoint)
    dTrackBar(TrackBIndex).Left=tPoint.x
    dTrackBar(TrackBIndex).Top=tPoint.y
    dTrackBar(TrackBIndex).Max=20

    SaveNewObjDataGrid(hWnd, token, ObjectIndex,tPoint.x, tPoint.y, dTrackBar(TrackBIndex).Width, _
                       dTrackBar(TrackBIndex).Height,0) '!!! сохранение таблицы

  else
    ReDrawComponentByField
  end if

  'INC ObjectIndex: INC TrackBIndex
END SUB

'*****************************************
Sub ShowObjects
  call  AddClrString ("--------------- 5192:ShowObjects=", subclr, LogEdit)
  flParsed=1 !!! '!!! global flag - show parsed object, not new.
  '!!! Property grid already exists

  flgPrnt=0 ' нашли корневого родителя. можно парсить дальше и расставлять компоненты на родителей
  pIdx=0

  defint cbi
  ' merge DefaultPropertyGrid and PropertyGrid  !!!!!! пока не будем -

  'DEFINT ObjectIndex    ' global index of added objects - added from component palette ans added from source parsing
  'DIM ObjectType(0 TO MAX_OBJECTS) AS string                          '!!! Component's type ie  QPANEL, QButton etc
  'DIM ObjTypeIndex(0 TO MAX_OBJECTS) as integer                       ' index of an object in the type group ie ObjTypeIndex(ObjIndex)
  'DIM ObjectHandle(0 TO MAX_OBJECTS) AS long                          '!!! Component's handle
  'DIM ObjectName(0 TO MAX_OBJECTS) AS string                          '!!! Component's name  ie Edit1, Panel1, StrinGrid3 etc
  'dim ObjVisible(0 TO MAX_OBJECTS) AS integer  ' ObjType of current oblect - visible or nonvisible
  'dim ObjParentIdx(0 TO MAX_OBJECTS) AS integer  ' ObjectIndex of the parents of the component(ObjectIndex)
  ' well.. if component(ObjectIndex) has a parent - ObjectIndex of this parent stored in ObjParentIdx(ObjectIndex), so
  'handle of the parent of component(ObjectIndex) stored in ObjectHandle(ObjParentIdx(ObjectIndex))


  parentCnt=0
  cbe=cmboxObj.ItemCount-1
  for cbi=0 to cbe
    if cbi>cmboxObj.ItemCount-1 then
      call  AddClrString ("5770:!!!!!!!!!!!!!!!!!!!!!!! cbi="+str$(cbi), &H00C700, LogEdit)
      'call  AddClrString ("5300:cmboxObj.ItemCount="+str$(cmboxObj.ItemCount), clred, LogEdit)

      exit for '!!! ShamanKING trick иначе не выходит из цикла !!!!!!!!!!!!!!!!!!!!!!
    end if
    call  AddClrString ("5293:-------- перебираем по комбобоксу и отрисовываем компоненты", cldи, LogEdit)
    '!!! По факту ObjectIndex это cmboxObj.ItemIndex, поскольку объекты по мере парсинга записываются в cmboxObj
    '!!! Хендл созданного объекта под номером ObjectIndex сохраняется в массиве ObjectHandle(ObjectIndex)
    '!!! Хендл родителя объекта под номером ObjectIndex находится в массиве ObjectHandle(ObjParentIdx(ObjectIndex)).

    '!!! проходим по объектам линейно и потом прикручиваем паренты согласно структуре из BuildObjTree
    ObjectIndex=cbi
    ObjectName(ObjectIndex)=field$(cmboxObj.Item(cbi)," ",1) '!!!  form1
    ObjectType(ObjectIndex)=trim$(field$(cmboxObj.Item(cbi)," as ",2)) '!!!  qform
    ObjectType(ObjectIndex)=trim$(field$(ObjectType(ObjectIndex)," ",1))

    call  AddClrString ("6497:ObjectName("+str$(ObjectIndex)+")="+(ObjectName(ObjectIndex)), clm, LogEdit)
    call  AddClrString ("6498:ObjectType("+str$(ObjectIndex)+")="+(ObjectType(ObjectIndex)), clm, LogEdit)
    call  AddClrString ("6499:ObjParentIdx("+str$(ObjectIndex)+")="+str$(ObjParentIdx(ObjectIndex)), clm, LogEdit)

    cmboxObj.ItemIndex=cbi
    'call  AddClrString ("5514:cbi="+str$(cbi), clo, LogEdit)
    'cmboxObj.Text= (ChildType$)

    cmboxObjOnChange

    'call  AddClrString ("5793:ObjectType("+str$(ObjectIndex)+")="+(ObjectType(ObjectIndex)), clred, LogEdit)
    NewObjectID=GetNewObjectID (ObjectType(ObjectIndex)) 'тип нового объекта
    'call  AddClrString ("6509:NewObjectID="+str$(NewObjectID), clb, LogEdit)


    if NewObjectID=0 then
      call  AddClrString ("9618:NewObjectID="+str$(NewObjectID), 0, LogEdit)
      AddNewForm
    else

      parentHwnd=ObjectHandle(ObjParentIdx(ObjectIndex))
      'call  AddClrString ("6517:parentHwnd="+str$(parentHwnd), cldg, LogEdit)
      if parentHwnd>0 then
        AddNewObject(parentHwnd) '!!! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      else
        'Showmessage ("Object "+ObjectName(ObjectIndex)+" has not parent")
        AddNewObject(parentHwnd) '!!! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        'call  AddClrString ("6523:wrong parentHwnd="+str$(parentHwnd), clred, LogEdit)
      end if


    end if

    'call  AddClrString ("5808: !!!!!!!!!!!!!!!!!! cbi="+str$(cbi), clp, LogEdit)
  next cbi

  OldObjectIndex=ObjectIndex

  flParsed=0 !!!
End Sub


'*****************************************
function GetNewObjectID (ObjType as string) as long 'QForm
  call  AddClrString ("5104:GetNewObjectID ObjType="+(ObjType), &H00ADA0, LogEdit)
  if ObjType="" then exit function
  dim ObjTypeList as QStringList

  if fileexists (StartPath$+"inc\RapidFRM.inc")>0 then
    ObjTypeList.LoadFromfile(StartPath$+"inc\RapidFRM.inc")
  else
    Showmessage("File not found "+"inc\RapidFRM.inc")
  end if
  '$DEFINE Q_FORM          0
  '$DEFINE Q_EDIT          1
  '$DEFINE Q_RICHEDIT      2
  '$DEFINE Q_LABEL         3
  ''call  AddClrString ("6296:ObjTypeList.ItemCount="+str$(ObjTypeList.ItemCount), clred, LogEdit)

  NewObjID$="9"
  for i=0 to ObjTypeList.ItemCount-1
    if instr(ObjTypeList.Item(i),"Q_")>0 then
      tmp1$=ObjTypeList.Item(i)-"$DEFINE " 'Q_LABEL         3.,
      tmp2$=tmp1$-"_" 'QLABEL         3
      ''call  AddClrString ("5114:tmp2$="+(tmp2$), &H9452A0, LogEdit)
      tmp3$=field$(tmp1$," ",1)
      if instr(tmp2$,ucase$(ObjType))>0 then
        NewObjID$=trim$(tmp1$-tmp3$)
        'call  AddClrString ("9648:NewObjID$="+(NewObjID$), clred, LogEdit)
        'GetNewObjectID=val(NewObjID$)
        exit for
      end if
    end if

  next

  GetNewObjectID=val(NewObjID$)



end function

'*****************************************

'-- ***************************************************************************************************
SUB  SaveAsOnClick        '' SaveAs item clicked

  SaveDialog.InitialDir=StartPath$
  SaveDialog.Filter ="*.bas|*.bas|*.rqb|*.rqb|_
  *.txt|*.txt|*.*|*.*"
  SaveDialog.FilterIndex = 1    '' Use "All Files" as our default


  SaveDialog.FileName=SrcFileName$ 'SrcFileName '+".bas"
  pntpos=instr(SaveDialog.Filter, ".")
  DelimPos=instr(SaveDialog.Filter, "|")
  xTFilter$=left$(SaveDialog.Filter, DelimPos-1) -"."-"*"
  'call  AddClrString ("4212:xTFilter$="+(xTFilter$), cldr, LogEdit)

  IF SaveDialog.Execute THEN
    'call  AddClrString ("4209:SaveDialog.Filter="+(SaveDialog.Filter), clred, LogEdit)
    'call  AddClrString ("4223:SaveDialog.FileName="+str$(SaveDialog.FileName), clred, LogEdit)


    if instr(SaveDialog.FileName,".")=0 then
      SaveDialog.FileName=SaveDialog.FileName+"."+xTFilter$
    end if
    Showmessage SaveDialog.FileName
    'brem 0
    '==========

    IF FileExists(SaveDialog.FileName) <> FALSE THEN
      IF MessageBox("Replace file"+chr$(10)+SaveDialog.FileName +" ?", "Warning!", 1) = 1 THEN
        a3333=9
      else
        'exit sub
        goto exitsub
      END IF
    END IF

    SrcFileName=SaveDialog.FileName
    '!!StatusPanel5.Caption=SrcFileName$
    ' если файл из списка окон, то при переименовании меняем название в списке
    'if EditFlg=0 then WindMnu(WindowsIndex).caption=str$(WindowsIndex)+ chr$(160)+SrcFileName

    if SaveString(SrcEdit.text ,SrcFileName$  )< 1 then
      'showmessage ("Can't save source into "+SrcFileName)
      'exit sub
    end if
    '!! SrcEdit.Modified=0
    'erem
    exitsub:
  ELSE
  END IF

END SUB

'*****************************************
SUB AddQTREEVIEW(hWnd AS long)
  'call  AddClrString ("5927:AddQTREEVIEW hWnd="+str$(hWnd), subclr, LogEdit)
  'DIM TreeView AS QTREEVIEW

  'reDIM panSplit(SplitCount) AS QPANEL
  'SplitIndex=SplitCount-1
  'inc SplitCount

  reDIM BoxTree(TreeVCount) AS QPANEL
  TreeVIndex=TreeVCount-1
  inc TreeVCount

  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  IF TreeVIndex>7 THEN                                            ' ONLY 1 allowed!
    MessageBox("Only 7 instance allowed!","RapidFRM "+VER,&h30)
    EXIT SUB
  END IF

  'BoxTree(TreeVIndex).Parent=Forms(FormIndex)                              ' MUST set a valid parent first!
  'IF hWnd<>Forms(FormIndex).Handle THEN
  'SetParent(BoxTree(TreeVIndex).Handle,hWnd)                             ' Set to correct parent
  'END IF


  '!----------------'! new procedure for get parent --------------
  prnt$=GetQParent (hWnd)
  prntName$=field$(prnt$,"_",1)
  call  AddClrString ("7253:prntName$="+(prntName$), clred, LogEdit)
  prntIdx$=field$(prnt$,"_",2)
  call  AddClrString ("7255:prntIdx$="+(prntIdx$), clred, LogEdit)
  prntIndex=val(prntIdx$)

  Select case prntName$
  case "forms"
    BoxTree(TreeVIndex).Parent=Forms(prntIndex)
  case "dpan"
    BoxTree(TreeVIndex).Parent=dpan(prntIndex)
  case "grpbox"
    BoxTree(TreeVIndex).Parent=grpbox(prntIndex)
  case "scrollb"
    BoxTree(TreeVIndex).Parent=scrollb(prntIndex)
  case "BoxTab"
    BoxTree(TreeVIndex).Parent=BoxTab(prntIndex)

  case else

  end select
  '! -------------------------------------

  call  AddClrString ("5944:TreeVIndex="+str$(TreeVIndex), clred, LogEdit)

  Select case TreeVIndex
  case 0
    TreeView0.Parent=BoxTree(TreeVIndex): TreeView0.Align=alClient:
    fld=GetPropValue ("color"):if fld>-999 then TreeView0.color=GetPropValue ("color")
    call  AddClrString ("5946:TreeView0.color="+str$(TreeView0.color), clred, LogEdit)

    TreeView0.ReadOnly=True: TreeView0.AddItems "1","2","3":
    TreeView0.AddChildItems 0, "Child A", "Child B", "Child C":TreeView0.AddChildItems 4, "Child X", "Child Y", "Child Z"

    fld=GetPropValue ("FullExpand"):
    if fld>-999 then
      'call  AddClrString ("5952:fld="+str$(fld), clred, LogEdit)
      TreeView0.FullExpand
    end if
    TreeView0.Enabled=False


  case 1
    TreeView1.Parent=BoxTree(TreeVIndex): TreeView1.Align=alClient: TreeView1.Enabled=False
    fld=GetPropValue ("color"):if fld>-999 then TreeView1.color=GetPropValue ("color")
    call  AddClrString ("7295:TreeView1.color="+str$(TreeView1.color), clred, LogEdit)

    TreeView1.ReadOnly=True: TreeView1.AddItems "1","2","3":
    TreeView1.AddChildItems 0, "Child A", "Child B", "Child C":TreeView1.AddChildItems 4, "Child X", "Child Y", "Child Z"

    fld=GetPropValue ("FullExpand"):
    call  AddClrString ("7300:fld="+str$(fld), clred, LogEdit)
    if fld>-999 then
      call  AddClrString ("7303:fld="+str$(fld), clred, LogEdit)
      TreeView1.FullExpand
    end if
    TreeView1.Enabled=False
    call  AddClrString ("7306:TreeView1.Enabled="+str$(TreeView1.Enabled), clred, LogEdit)

  case 2
    TreeView2.Parent=BoxTree(TreeVIndex): TreeView2.Align=alClient: TreeView2.Enabled=False
    fld=GetPropValue ("color"):if fld>-999 then TreeView2.color=GetPropValue ("color")
    ''call  AddClrString ("5946:TreeView0.color="+str$(TreeView0.color), clred, LogEdit)

    TreeView2.ReadOnly=True: TreeView2.AddItems "1","2","3":
    TreeView2.AddChildItems 0, "Child A", "Child B", "Child C":TreeView2.AddChildItems 4, "Child X", "Child Y", "Child Z"

    fld=GetPropValue ("FullExpand"):
    if fld>-999 then
      'call  AddClrString ("5952:fld="+str$(fld), clred, LogEdit)
      TreeView2.FullExpand
    end if
    TreeView2.Enabled=False

  case 3
    TreeView3.Parent=BoxTree(TreeVIndex): TreeView3.Align=alClient: TreeView3.Enabled=False
    fld=GetPropValue ("color"):if fld>-999 then TreeView2.color=GetPropValue ("color")
    ''call  AddClrString ("5946:TreeView0.color="+str$(TreeView0.color), clred, LogEdit)

    TreeView3.ReadOnly=True: TreeView3.AddItems "1","2","3":
    TreeView3.AddChildItems 0, "Child A", "Child B", "Child C":TreeView3.AddChildItems 4, "Child X", "Child Y", "Child Z"

    fld=GetPropValue ("FullExpand"):
    if fld>-999 then
      'call  AddClrString ("5952:fld="+str$(fld), clred, LogEdit)
      TreeView3.FullExpand
    end if
    TreeView3.Enabled=False
  case 4
    TreeView4.Parent=BoxTree(TreeVIndex): TreeView4.Align=alClient: TreeView4.Enabled=False
    fld=GetPropValue ("color"):if fld>-999 then TreeView4.color=GetPropValue ("color")
    TreeView4.ReadOnly=True: TreeView2.AddItems "1","2","3":
    TreeView4.AddChildItems 0, "Child A", "Child B", "Child C":TreeView4.AddChildItems 4, "Child X", "Child Y", "Child Z"
    fld=GetPropValue ("FullExpand"):if fld>-999 then TreeView4.FullExpand
    TreeView4.Enabled=False
  case 5
    TreeView5.Parent=BoxTree(TreeVIndex): TreeView5.Align=alClient: TreeView5.Enabled=False
    fld=GetPropValue ("color"):if fld>-999 then TreeView5.color=GetPropValue ("color")
    TreeView5.ReadOnly=True: TreeView5.AddItems "1","2","3":
    TreeView5.AddChildItems 0, "Child A", "Child B", "Child C":TreeView5.AddChildItems 4, "Child X", "Child Y", "Child Z"
    fld=GetPropValue ("FullExpand"):if fld>-999 then TreeView5.FullExpand
    TreeView5.Enabled=False
  case 6
    TreeView6.Parent=BoxTree(TreeVIndex): TreeView6.Align=alClient: TreeView6.Enabled=False
    fld=GetPropValue ("color"):if fld>-999 then TreeView6.color=GetPropValue ("color")
    TreeView6.ReadOnly=True: TreeView6.AddItems "1","2","3":
    TreeView6.AddChildItems 0, "Child A", "Child B", "Child C":TreeView6.AddChildItems 4, "Child X", "Child Y", "Child Z"
    fld=GetPropValue ("FullExpand"):if fld>-999 then TreeView6.FullExpand
    TreeView6.Enabled=False
  case 7
    TreeView7.Parent=BoxTree(TreeVIndex): TreeView7.Align=alClient: TreeView7.Enabled=False
    fld=GetPropValue ("color"):if fld>-999 then TreeView7.color=GetPropValue ("color")
    TreeView7.ReadOnly=True: TreeView7.AddItems "1","2","3":
    TreeView7.AddChildItems 0, "Child A", "Child B", "Child C":TreeView7.AddChildItems 4, "Child X", "Child Y", "Child Z"
    fld=GetPropValue ("FullExpand"):if fld>-999 then TreeView7.FullExpand
    TreeView7.Enabled=False

  case else
    'TreeView0.Parent=BoxTree(TreeVIndex): TreeView0.Align=alClient: TreeView0.Enabled=False
  end select


  ObjectType(ObjectIndex)="QTREEVIEW"
  ObjTypeIndex(ObjectIndex)=TreeVIndex
  ObjectHandle(ObjectIndex)=BoxTree(TreeVIndex).Handle

  if flParsed=0 then ' свойства!!!  компонента, если он устанавливается с палитры

    token="TreeView"+STR$(TreeVIndex)+" "
    BoxTree(TreeVIndex).Width=320
    BoxTree(TreeVIndex).Height=100
    tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
    ScreenToClient(hWnd,tPoint)
    BoxTree(TreeVIndex).Left=tPoint.x-2
    BoxTree(TreeVIndex).Top=tPoint.y-2
    SaveNewObjDataGrid(hWnd, token, ObjectIndex,tPoint.x, tPoint.y, BoxTree(TreeVIndex).Width, BoxTree(TreeVIndex).Height,BoxTree(TreeVIndex).Color) '!!! сохранение таблицы

  else
    ReDrawComponentByField
  end if

END SUB

'*****************************************
SUB AddQOUTLINE(hWnd AS long)
  'reDIM frmOutLine(OutLnIndex+1) AS QOUTLINE
  reDIM BoxOutLine(OutLnCount) AS QPANEL
  OutLnIndex=OutLnCount-1
  inc OutLnCount

  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  IF OutLnIndex>7 THEN                                            ' ONLY 1 allowed!
    MessageBox("Only 7 instances allowed!","RapidFRM "+VER,&h30)
    EXIT SUB
  END IF

  'BoxOutLine(OutLnIndex).Parent=Forms(FormIndex)                            ' MUST set a valid parent first!
  'IF hWnd<>Forms(FormIndex).Handle THEN
  'SetParent(BoxOutLine(OutLnIndex).Handle,hWnd)                           ' Set to correct parent
  'END IF

  '!----------------'! new procedure for get parent --------------
  prnt$=GetQParent (hWnd)
  prntName$=field$(prnt$,"_",1)
  call  AddClrString ("7414:prntName$="+(prntName$), clred, LogEdit)
  prntIdx$=field$(prnt$,"_",2)
  call  AddClrString ("7416:prntIdx$="+(prntIdx$), clred, LogEdit)
  prntIndex=val(prntIdx$)

  Select case prntName$
  case "forms"
    BoxOutLine(OutLnIndex).Parent=Forms(prntIndex)
  case "dpan"
    BoxOutLine(OutLnIndex).Parent=dpan(prntIndex)
  case "grpbox"
    BoxOutLine(OutLnIndex).Parent=grpbox(prntIndex)
  case "scrollb"
    BoxOutLine(OutLnIndex).Parent=scrollb(prntIndex)
  case "BoxTab"
    BoxOutLine(OutLnIndex).Parent=BoxTab(prntIndex)

  case else

  end select
  '! -------------------------------------

  token="OutLine"+STR$(OutLnIndex)+" "
  call  AddClrString ("7434:token="+(token), clred, LogEdit)


  Select case OutLnIndex
  case 0
    frmOutLine0.Parent=BoxOutLine(OutLnIndex): frmOutLine0.Align=alClient: frmOutLine0.Enabled=False
    call  AddClrString ("7440:OutLnIndex="+str$(OutLnIndex), clred, LogEdit)
    frmOutLine0.AddLines token,"Child1","Child2":
    call  AddClrString ("7444:token="+(token), clred, LogEdit)
    frmOutLine0.AddLines "Parent2","Child1","Child2"
    call  AddClrString ("7447:token="+str$(token), clred, LogEdit)
    fld=clw'GetPropValue ("color"):
    call  AddClrString ("7448:fld="+str$(fld), clred, LogEdit)
    if fld>-999 then frmOutLine0.color=fld
    call  AddClrString ("7449:fld="+str$(fld), clred, LogEdit)

  case 1
    frmOutLine1.Parent=BoxOutLine(OutLnIndex): frmOutLine1.Align=alClient: frmOutLine1.Enabled=False
    call  AddClrString ("7446:OutLnIndex="+str$(OutLnIndex), clred, LogEdit)
    frmOutLine1.AddLines token,"Child1","Child2": frmOutLine1.AddLines "Parent2","Child1","Child2"
    fld=clw'GetPropValue ("color"):
    if fld>-999 then frmOutLine1.color=fld
    call  AddClrString ("7452:frmOutLine1.color="+str$(frmOutLine1.color), clred, LogEdit)
    call  AddClrString ("7452:fld="+str$(fld), clred, LogEdit)
  case 2
    frmOutLine2.Parent=BoxOutLine(OutLnIndex): frmOutLine2.Align=alClient: frmOutLine2.Enabled=False
    frmOutLine2.AddLines token,"Child1","Child2": frmOutLine2.AddLines "Parent2","Child1","Child2"
    fld=clw'GetPropValue ("color"):
    if fld>-999 then frmOutLine2.color=fld
  case 3
    frmOutLine3.Parent=BoxOutLine(OutLnIndex): frmOutLine3.Align=alClient: frmOutLine3.Enabled=False
    frmOutLine3.AddLines token,"Child1","Child2": frmOutLine3.AddLines "Parent2","Child1","Child2"
    fld=clw'GetPropValue ("color"):
    if fld>-999 then frmOutLine3.color=fld
  case 4
    frmOutLine4.Parent=BoxOutLine(OutLnIndex): frmOutLine4.Align=alClient: frmOutLine4.Enabled=False
    frmOutLine4.AddLines token,"Child1","Child2": frmOutLine4.AddLines "Parent2","Child1","Child2"
    fld=GetPropValue ("color"):if fld>-999 then frmOutLine4.color=fld
  case 5
    frmOutLine5.Parent=BoxOutLine(OutLnIndex): frmOutLine5.Align=alClient: frmOutLine5.Enabled=False
    frmOutLine5.AddLines token,"Child1","Child2": frmOutLine5.AddLines "Parent2","Child1","Child2"
    fld=GetPropValue ("color"):if fld>-999 then frmOutLine5.color=fld
  case 6
    frmOutLine6.Parent=BoxOutLine(OutLnIndex): frmOutLine6.Align=alClient: frmOutLine6.Enabled=False
    frmOutLine6.AddLines token,"Child1","Child2": frmOutLine6.AddLines "Parent2","Child1","Child2"
    fld=GetPropValue ("color"):if fld>-999 then frmOutLine6.color=fld
  case 7
    frmOutLine7.Parent=BoxOutLine(OutLnIndex): frmOutLine7.Align=alClient: frmOutLine7.Enabled=False
    frmOutLine7.AddLines token,"Child1","Child2": frmOutLine7.AddLines "Parent2","Child1","Child2"
    fld=GetPropValue ("color"):if fld>-999 then frmOutLine7.color=fld

  case else
    frmOutLine0.Parent=BoxOutLine(OutLnIndex): frmOutLine0.Align=alClient: frmOutLine0.Enabled=False
    frmOutLine0.AddLines token,"Child1","Child2": frmOutLine0.AddLines "Parent2","Child1","Child2"
    fld=GetPropValue ("color"):if fld>-999 then frmOutLine0.color=fld
  end select


  ObjectType(ObjectIndex)="QOUTLINE"
  call  AddClrString ("7487:ObjectIndex="+str$(ObjectIndex), clred, LogEdit)
  call  AddClrString ("7487:QOUTLINE=", clb, LogEdit)

  call  AddClrString ("7483:ObjectType("+str$(ObjectIndex)+")="+str$(ObjectType(ObjectIndex)), clred, LogEdit)
  ObjTypeIndex(ObjectIndex)=OutLnIndex
  call  AddClrString ("7483:OutLnIndex="+str$(OutLnIndex), clred, LogEdit)
  ObjectHandle(ObjectIndex)=BoxOutLine(OutLnIndex).Handle

  if flParsed=0 then ' свойства!!!  компонента, если он устанавливается с палитры

    BoxOutLine(OutLnIndex).Width=120
    BoxOutLine(OutLnIndex).Height=100


    token="OutLine"+STR$(OutLnIndex)+" "
    call  AddClrString ("7492:token="+(token), clred, LogEdit)

    tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
    ScreenToClient(hWnd,tPoint)
    BoxOutLine(OutLnIndex).Left=tPoint.x-2
    BoxOutLine(OutLnIndex).Top=tPoint.y-2
    call  AddClrString ("7498:BoxOutLine("+str$(OutLnIndex)+"Top)="+str$(BoxOutLine(OutLnIndex).Top), clred, LogEdit)

    SaveNewObjDataGrid(hWnd, token, ObjectIndex,tPoint.x, tPoint.y, BoxOutLine(OutLnIndex).Width, BoxOutLine(OutLnIndex).Height,BoxOutLine(OutLnIndex).Color) '!!! сохранение таблицы

  else
    ReDrawComponentByField
  end if


END SUB

'*****************************************
SUB AddQOLECONTAINER(hWnd AS long)                                  ' Fudge using QPANEL
  reDIM oleContainer(OLEContCount) AS QPANEL
  OLEContIndex=OLEContCount-1
  inc OLEContCount

  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  'IF hWnd<>Forms(FormIndex).Handle THEN
  'SetParent(oleContainer(OLEContIndex).Handle,hWnd)           ' Set to correct parent
  'END IF
  oleContainer(OLEContIndex).BevelOuter=2
  'oleContainer(OLEContIndex).Parent=Forms(FormIndex)            ' MUST set a valid parent first!

  '!----------------'! new procedure for get parent --------------
  prnt$=GetQParent (hWnd)
  prntName$=field$(prnt$,"_",1)
  call  AddClrString ("5724:prntName$="+(prntName$), clred, LogEdit)
  prntIdx$=field$(prnt$,"_",2)
  call  AddClrString ("5726:prntIdx$="+(prntIdx$), clred, LogEdit)
  prntIndex=val(prntIdx$)

  Select case prntName$
  case "forms"
    oleContainer(OLEContIndex).Parent=Forms(prntIndex)
  case "dpan"
    oleContainer(OLEContIndex).Parent=dpan(prntIndex)
  case "grpbox"
    oleContainer(OLEContIndex).Parent=grpbox(prntIndex)
  case "scrollb"
    oleContainer(OLEContIndex).Parent=scrollb(prntIndex)
  case "BoxTab"
    oleContainer(OLEContIndex).Parent=BoxTab(prntIndex)

  case else

  end select
  '! -------------------------------------




  ObjectType(ObjectIndex)="QOLECONTAINER"
  ObjTypeIndex(ObjectIndex)=OLEContIndex

  if flParsed=0 then ' свойства!!!  компонента, если он устанавливается с палитры


    token="OLEContainer"+STR$(OLEContIndex)+" "
    oleContainer(OLEContIndex).Width=100
    oleContainer(OLEContIndex).Height=100
    tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
    ScreenToClient(hWnd,tPoint)
    oleContainer(OLEContIndex).Left=tPoint.x
    oleContainer(OLEContIndex).Top=tPoint.y
    oleContainer(OLEContIndex).Caption=token


    'tstr=STR$(NewObjectID)+"|QOLECONTAINER|"+STR$(oleContainer(OLEContIndex).Handle)+"|"+token+"|"+token+"|"+STR$(hWnd)+"~"
    'AddedObjectList(ObjectIndex)=tstr+GetDefaultProperties(NewObjectID)

    PropertyFieldUpdate("Left",STR$(tPoint.x))                    '
    PropertyFieldUpdate("Top",STR$(tPoint.y))                     ' Update new properties in AddedObjectList..
    PropertyFieldUpdate("Caption",token)                          '
    PropertyFieldUpdate("Parent",WhichParent(hWnd))               '

    'SelectionCombo.AddItems token+" [QOLECONTAINER]"
    'SelectionCombo.ItemIndex=ObjectIndex
    'UpdatePropGrid(ObjectIndex)                                   ' Update String grid
    SaveNewObjDataGrid(hWnd, token, ObjectIndex,tPoint.x, tPoint.y, oleContainer(OLEContIndex).Width,_
                       oleContainer(OLEContIndex).Height,oleContainer(OLEContIndex).Color) '!!! сохранение таблицы

  else
    ReDrawComponentByField
  end if


END SUB

'*****************************************
SUB AddQCANVAS(hWnd AS long)                                        ' Fudge using QPANEL
  'call  AddClrString ("6307:AddQCANVAS hWnd="+str$(hWnd), subclr, LogEdit)
  reDIM panCanv(CanvasCount) AS QPANEL
  reDIM Canv(CanvasCount) AS QCanvas

  CanvasIndex=CanvasCount-1
  inc CanvasCount

  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  'panCanv(CanvasIndex).Parent=Forms(FormIndex)                  ' MUST set a valid parent first!
  'IF hWnd<>Forms(FormIndex).Handle THEN
  'SetParent(panCanv(CanvasIndex).Handle,hWnd)                 ' Set to correct parent
  'END IF

  '!----------------'! new procedure for get parent --------------
  prnt$=GetQParent (hWnd)
  prntName$=field$(prnt$,"_",1)
  call  AddClrString ("5724:prntName$="+(prntName$), clred, LogEdit)
  prntIdx$=field$(prnt$,"_",2)
  call  AddClrString ("5726:prntIdx$="+(prntIdx$), clred, LogEdit)
  prntIndex=val(prntIdx$)

  Select case prntName$
  case "forms"
    panCanv(CanvasIndex).Parent=Forms(prntIndex)
  case "dpan"
    panCanv(CanvasIndex).Parent=dpan(prntIndex)
  case "grpbox"
    panCanv(CanvasIndex).Parent=grpbox(prntIndex)
  case "scrollb"
    panCanv(CanvasIndex).Parent=scrollb(prntIndex)
  case "BoxTab"
    panCanv(CanvasIndex).Parent=BoxTab(prntIndex)

  case else

  end select
  '! -------------------------------------


  panCanv(CanvasIndex).caption="panCanv("+str$(CanvasIndex)+")"
  Canv(CanvasIndex).Parent=panCanv(CanvasIndex)
  Canv(CanvasIndex).Align=alClient
  Canv(CanvasIndex).Textout (5,5,str$(CanvasIndex)+" Beware the power of Rapid-Q!", &H00FF00, 0)
  Canv(CanvasIndex).Textout (5,15,"Credit Scroller written in Rapid-Q by William Yu", &HFFFFFF, 0)
  Canv(CanvasIndex).enabled=0
  'sleep 15

  ObjectType(ObjectIndex)="QCANVAS"
  ObjTypeIndex(ObjectIndex)=CanvasIndex
  ObjectHandle(ObjectIndex)=panCanv(CanvasIndex).Handle

  if flParsed=0 then ' свойства!!!  компонента, если он устанавливается с палитры

    token="Canvas"+STR$(CanvasIndex)+" "
    panCanv(CanvasIndex).Width=100
    panCanv(CanvasIndex).Height=100
    tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
    ScreenToClient(hWnd,tPoint)
    panCanv(CanvasIndex).Left=tPoint.x
    panCanv(CanvasIndex).Top=tPoint.y
    panCanv(CanvasIndex).Caption=token

    SaveNewObjDataGrid(hWnd, token, ObjectIndex,tPoint.x, tPoint.y, panCanv(CanvasIndex).Width, _
                       panCanv(CanvasIndex).Height,panCanv(CanvasIndex).Color) '!!! сохранение таблицы
  else
    ReDrawComponentByField
  end if

END SUB

'*****************************************
SUB AddQIMAGE(hWnd AS long)                                         ' Fudge using QPANEL
  'call  AddClrString ("6453:AddQIMAGE hWnd="+str$(hWnd), subclr, LogEdit)
  reDIM panImage(ImageCount) AS QPANEL
  reDIM Imag(ImageCount) AS QImage
  'DIM panImage(32) AS QPANEL

  ImageIndex=ImageCount-1
  inc ImageCount

  DEFSTR tstr, token
  DIM tPoint AS PointAPI


  'panImage(ImageIndex).Parent=Forms(FormIndex)                  ' MUST set a valid parent first!
  'IF hWnd<>Forms(FormIndex).Handle THEN
  'SetParent(panImage(ImageIndex).Handle,hWnd)                 ' Set to correct parent
  'END IF

  '!----------------'! new procedure for get parent --------------
  prnt$=GetQParent (hWnd)
  prntName$=field$(prnt$,"_",1)
  call  AddClrString ("5724:prntName$="+(prntName$), clred, LogEdit)
  prntIdx$=field$(prnt$,"_",2)
  call  AddClrString ("5726:prntIdx$="+(prntIdx$), clred, LogEdit)
  prntIndex=val(prntIdx$)

  Select case prntName$
  case "forms"
    panImage(ImageIndex).Parent=Forms(prntIndex)
  case "dpan"
    panImage(ImageIndex).Parent=dpan(prntIndex)
  case "grpbox"
    panImage(ImageIndex).Parent=grpbox(prntIndex)
  case "scrollb"
    panImage(ImageIndex).Parent=scrollb(prntIndex)
  case "BoxTab"
    panImage(ImageIndex).Parent=BoxTab(prntIndex)

  case else

  end select
  '! -------------------------------------


  panImage(ImageIndex).Caption=token

  ObjectType(ObjectIndex)="QIMAGE"
  ObjTypeIndex(ObjectIndex)=ImageIndex
  ObjectHandle(ObjectIndex)=panImage(ImageIndex).Handle

  'panImage(ImageIndex).BevelOuter=2
  panImage(ImageIndex).Color=&hffffff

  Imag(ImageIndex).Parent=panImage(ImageIndex)
  Imag(ImageIndex).Align=alClient
  Imag(ImageIndex).enabled=0


  if flParsed=0 then ' свойства!!!  компонента, если он устанавливается с палитры

    token="Image"+STR$(ImageIndex)+" "
    panImage(ImageIndex).Width=100
    panImage(ImageIndex).Height=100
    tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
    ScreenToClient(hWnd,tPoint)
    panImage(ImageIndex).Left=tPoint.x
    panImage(ImageIndex).Top=tPoint.y

  else
    ReDrawComponentByField
  end if

  'INC ObjectCount: INC ImageIndex

END SUB








'*****************************************
SUB AddQEDIT(hWnd AS long) ' hWnd is handle of the window where was clicked
  call  AddClrString ("-------------- 3679:AddQEDIT=", 0, LogEdit)
  '!reDIM panImage(ImageCount) AS QPANEL
  '!reDIM Imag(ImageCount) AS QImage
  'DIM panImage(32) AS QPANEL

  '!ImageIndex=ImageCount-1
  '!inc ImageCount


  reDim BoxEdit(EdCount) AS QPANEL
  EdIndex=EdCount-1
  inc EdCount

  DEFSTR tstr, token
  DIM tPoint AS PointAPI
  call  AddClrString ("2858:EdIndex="+str$(EdIndex), cldr, LogEdit)
  BoxEdit(EdIndex).Width=100                                      ' Using a QPanel so set these...
  BoxEdit(EdIndex).Height=25                                      ' ...to the defaults of QEdit
  BoxEdit(EdIndex).Color=&hffffff
  BoxEdit(EdIndex).BevelOuter=bvNone'2
  BoxEdit(EdIndex).Alignment=taLeftJustify
  token="Edit"+STR$(EdIndex+1)
  BoxEdit(EdIndex).Caption=token
  call  AddClrString ("3691:token="+str$(token), clred, LogEdit)

  BoxEdit(EdIndex).Parent=Forms(FormIndex)                      ' MUST set a valid parent first!
  IF hWnd<>Forms(FormIndex).Handle THEN
    SetParent(BoxEdit(EdIndex).Handle,hWnd)                     ' Set to correct parent
  END IF

  tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
  ScreenToClient(hWnd,tPoint)                                     ' Posn relative to parent
  BoxEdit(EdIndex).Left=tPoint.x
  BoxEdit(EdIndex).Top=tPoint.y
  CurrentObject=ObjectIndex
  ObjectType(CurrentObject)="QEDIT"
  ObjTypeIndex(CurrentObject)=EdIndex
  call  AddClrString ("3705:EdIndex="+str$(EdIndex), clred, LogEdit)

  tstr=STR$(NewObjectID)+"|QEDIT|"+STR$(BoxEdit(EdIndex).Handle)+"|"+token+"|"+token+"|"+STR$(hWnd)+"~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(NewObjectID)

  PropertyFieldUpdate("Left",STR$(tPoint.x))',4                    '
  PropertyFieldUpdate("Top",STR$(tPoint.y))',4                     ' Update new properties in AddedObjectList..
  PropertyFieldUpdate("Caption",token)',4                          ' ..Width & Height defaults
  PropertyFieldUpdate("Parent",WhichParent(hWnd))',4               '
  'ReDrawComponentbyField


  SelectionCombo.AddItems token+" [QEDIT]"
  SelectionCombo.ItemIndex=CurrentObject

  'call  AddClrString ("3715:UpdatePropGrid="+str$(UpdatePropGrid), clred, LogEdit)

  UpdatePropGrid(CurrentObject)
  call  AddClrString ("3736:CurrentObject="+str$(CurrentObject), clo, LogEdit)
  ' Update String grid data
  'call  AddClrString ("-----------2906:CurrentObject="+str$(CurrentObject), clred, LogEdit)

  INC ObjectIndex: INC EdIndex

  ' надо сделать массив индексов ObjTypeIndex(ObjectIndex)=EdIndex
  ' то есть потом можно будет обращаться к объекту по его индексу в массиве
  brem 0
  if ObjectType(ObjectIndex)="QEDIT" then ' если тип данного объекта QEDIT
    EdIndex=ObjTypeIndex(ObjectIndex) ' берем его индекс и устанавливаем свойства напрямую, а не через winapi по хендлу
    BoxEdit(EdIndex).color=clr
    BoxEdit(EdIndex).font=
    BoxEdit(EdIndex)./////
  end if

  erem


END SUB

'*****************************************
SUB AddQRICHEDIT(hWnd AS long)
  reDIM BoxRich(RichIndex+1) AS QPANEL
  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  BoxRich(RichIndex).Width=200                                    ' Using a QPanel so MUST set these...
  BoxRich(RichIndex).Height=100                                   ' ...to the defaults of QRichEdit
  BoxRich(RichIndex).Color=&hffffff
  BoxRich(RichIndex).BevelOuter=2
  BoxRich(RichIndex).Alignment=taLeftJustify
  token="RichEd"+STR$(RichIndex+1)
  BoxRich(RichIndex).Caption=token

  BoxRich(RichIndex).Parent=Forms(FormIndex)                    ' MUST set a valid parent first!
  IF hWnd<>Forms(FormIndex).Handle THEN
    SetParent(BoxRich(RichIndex).Handle,hWnd)
  END IF
  tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
  ScreenToClient(hWnd,tPoint)
  BoxRich(RichIndex).Left=tPoint.x
  BoxRich(RichIndex).Top=tPoint.y
  CurrentObject=ObjectIndex

  ObjectType(CurrentObject)="QRICHEDIT"
  ObjTypeIndex(CurrentObject)=RichIndex


  tstr=STR$(NewObjectID)+"|QRICHEDIT|"+STR$(BoxRich(RichIndex).Handle)+"|"+token+"|"+token+"|"+STR$(hWnd)+"~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(NewObjectID)
  PropertyFieldUpdate("Left",STR$(tPoint.x))',4                    '
  PropertyFieldUpdate("Top",STR$(tPoint.y))',4                     ' Update new properties in AddedObjectList..
  PropertyFieldUpdate("Caption",token)',4                          ' ..Width & Height defaults
  PropertyFieldUpdate("Parent",WhichParent(hWnd))',4               '


  SelectionCombo.AddItems token+" [QRICHEDIT]"
  SelectionCombo.ItemIndex=CurrentObject
  UpdatePropGrid(CurrentObject)                                   ' Update String grid


  INC ObjectIndex: INC RichIndex
END SUB

'*****************************************
SUB AddQLABEL1(hWnd AS long)
  reDIM BoxLabel(LabelIndex+1) AS QPANEL
  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  BoxLabel(LabelIndex).Width=75                                   ' Using a QPanel so MUST set...
  BoxLabel(LabelIndex).Height=25                                  ' .. these to the defaults of QLabel
  BoxLabel(LabelIndex).BevelOuter=2
  BoxLabel(LabelIndex).Alignment=taLeftJustify
  token="Label"+STR$(LabelIndex+1)
  BoxLabel(LabelIndex).Caption=token

  BoxLabel(LabelIndex).Parent=Forms(FormIndex)                  ' MUST set a valid parent first!
  IF hWnd<>Forms(FormIndex).Handle THEN
    SetParent(BoxLabel(LabelIndex).Handle,hWnd)                 ' Set to the currect parent
  END IF
  tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
  ScreenToClient(hWnd,tPoint)
  BoxLabel(LabelIndex).Left=tPoint.x
  BoxLabel(LabelIndex).Top=tPoint.y
  CurrentObject=ObjectIndex
  ObjectType(CurrentObject)="QLABEL"
  ObjTypeIndex(CurrentObject)=LabelIndex

  tstr=STR$(NewObjectID)+"|QLABEL|"+STR$(BoxLabel(LabelIndex).Handle)+"|"+token+"|"+token+"|"+STR$(hWnd)+"~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(NewObjectID)
  PropertyFieldUpdate("Left",STR$(tPoint.x)) ',4)                    '
  PropertyFieldUpdate("Top",STR$(tPoint.y)) ',4)                     ' Update new properties in AddedObjectList..
  PropertyFieldUpdate("Caption",token) ',4)                          ' ..Width & Height defaults
  PropertyFieldUpdate("Parent",WhichParent(hWnd)) ',4)               '


  SelectionCombo.AddItems token+" [QLABEL]"
  SelectionCombo.ItemIndex=CurrentObject
  UpdatePropGrid(CurrentObject)                                   ' Update String grid

  INC ObjectIndex: INC LabelIndex
END SUB

'*****************************************
SUB AddQBUTTON(hWnd AS long)
  reDIM boxBut(ButnIndex+1) AS QPANEL                                   ' Fudge using QPANEL
  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  boxBut(ButnIndex).Width=75                                      ' Using a QPanel so set these...
  boxBut(ButnIndex).Height=25                                     ' ...to the defaults of QButton
  boxBut(ButnIndex).BevelOuter=2
  token="Butn"+STR$(ButnIndex+1)
  boxBut(ButnIndex).Caption=token

  boxBut(ButnIndex).Parent=Forms(FormIndex)                     ' MUST set a valid parent first!
  IF hWnd<>Forms(FormIndex).Handle THEN
    SetParent(boxBut(ButnIndex).Handle,hWnd)
  END IF
  tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
  ScreenToClient(hWnd,tPoint)
  boxBut(ButnIndex).Left=tPoint.x
  boxBut(ButnIndex).Top=tPoint.y
  CurrentObject=ObjectIndex

  ObjectType(CurrentObject)="QBUTTON"
  ObjTypeIndex(CurrentObject)=ButnIndex

  tstr=STR$(NewObjectID)+"|QBUTTON|"+STR$(boxBut(ButnIndex).Handle)+"|"+token+"|"+token+"|"+STR$(hWnd)+"~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(NewObjectID)
  PropertyFieldUpdate("Left",STR$(tPoint.x)) ',4)                    '
  PropertyFieldUpdate("Top",STR$(tPoint.y)) ',4)                     ' Update new properties in AddedObjectList..
  PropertyFieldUpdate("Caption",token) ',4)                          ' ..Width & Height defaults
  PropertyFieldUpdate("Parent",WhichParent(hWnd)) ',4)               '



  SelectionCombo.AddItems token+" [QBUTTON]"
  SelectionCombo.ItemIndex=CurrentObject

  UpdatePropGrid(CurrentObject)                                   ' Update String grid
  INC ObjectIndex: INC ButnIndex
END SUB

'*****************************************
SUB AddQCOOLBTN(hWnd AS long)
  reDIM BoxCool(CoolIndex+1) AS QPANEL                                  ' Fudge using QPANEL

  'DIM BoxCool(CoolIndex+1) AS QCOOLBTN                                  ' Fudge using QPANEL


  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  BoxCool(CoolIndex).Width=25                                     ' Using a QPanel so MUST set...
  BoxCool(CoolIndex).Height=25                                    ' .. these to the defaults of QCoolBtn
  BoxCool(CoolIndex).BevelOuter=2
  token="Cool"+STR$(CoolIndex+1)
  BoxCool(CoolIndex).Caption=token

  BoxCool(CoolIndex).Parent=Forms(FormIndex)                    ' MUST set a valid parent first!
  IF hWnd<>Forms(FormIndex).Handle THEN
    SetParent(BoxCool(CoolIndex).Handle,hWnd)                   ' Set to correct parent
  END IF
  tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
  ScreenToClient(hWnd,tPoint)
  BoxCool(CoolIndex).Left=tPoint.x
  BoxCool(CoolIndex).Top=tPoint.y
  CurrentObject=ObjectIndex

  ObjectType(CurrentObject)="QCOOLBTN"
  ObjTypeIndex(CurrentObject)=CoolIndex

  tstr=STR$(NewObjectID)+"|QCOOLBTN|"+STR$(BoxCool(CoolIndex).Handle)+"|"+token+"|"+token+"|"+STR$(hWnd)+"~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(NewObjectID)
  PropertyFieldUpdate("Left",STR$(tPoint.x)) ',4)                    '
  PropertyFieldUpdate("Top",STR$(tPoint.y)) ',4)                     ' Update new properties in AddedObjectList..
  PropertyFieldUpdate("Caption",token) ',4)                          ' ..Width & Height defaults
  PropertyFieldUpdate("Parent",WhichParent(hWnd)) ',4)               '

  SelectionCombo.AddItems token+" [QCOOLBTN]"
  SelectionCombo.ItemIndex=CurrentObject

  UpdatePropGrid(CurrentObject)                                   ' Update String grid
  INC ObjectIndex: INC CoolIndex
END SUB

'*****************************************
SUB AddQOVALBTN1(hWnd AS long)
  STATIC QOVALIndex
  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  INC QOVALIndex '!!! increment here !!
  REDIM panOval(QOVALIndex) AS QPANEL
  REDIM imgOval(QOVALIndex) AS QCANVAS

  token="OvalBtn"+STR$(QOVALIndex)
  panOval(QOVALIndex).Parent=Forms(FormIndex)                            ' MUST set a valid parent first!
  IF hWnd<>Forms(FormIndex).Handle THEN
    SetParent(panOval(QOVALIndex).Handle,hWnd)                           ' Set to correct parent
  END IF
  tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
  ScreenToClient(hWnd,tPoint)
  panOval(QOVALIndex).Left=tPoint.x
  panOval(QOVALIndex).Top=tPoint.y
  panOval(QOVALIndex).Width=75                                             ' Using a QPanel so MUST set...
  panOval(QOVALIndex).Height=40                                            ' .. these to the defaults of QOvalBtn
  panOval(QOVALIndex).BevelWidth=0
  panOval(QOVALIndex).Caption=token

  imgOval(QOVALIndex).Parent=panOval(QOVALIndex)
  imgOval(QOVALIndex).Align=alClient
  imgOval(QOVALIndex).Enabled=False                                        ' Passes clicks thru to panel
  imgOval(QOVALIndex).Tag=QOVALIndex                                                ' Used when drawing the btn
  imgOval(QOVALIndex).OnPaint=OvalPaint
  CurrentObject=ObjectIndex

  ObjectType(CurrentObject)="QOVALBTN"
  ObjTypeIndex(CurrentObject)=QOVALIndex


  tstr=STR$(NewObjectID)+"|QOVALBTN|"+STR$(panOval(QOVALIndex).Handle)+"|"+token+ _
  "|"+token+"|"+STR$(hWnd)+"|"+STR$(QOVALIndex)+"~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(NewObjectID)
  PropertyFieldUpdate("Left",STR$(tPoint.x)) ',4)                    '
  PropertyFieldUpdate("Top",STR$(tPoint.y)) ',4)                     ' Update new properties in AddedObjectList..
  PropertyFieldUpdate("Caption",token) ',4)                          ' ..Width & Height defaults
  PropertyFieldUpdate("Parent",WhichParent(hWnd)) ',4)               '

  SelectionCombo.AddItems token+" [QOVALBTN]"
  SelectionCombo.ItemIndex=CurrentObject

  UpdatePropGrid(CurrentObject)                                   ' Update String grid
  INC ObjectIndex
END SUB

'*****************************************
SUB AddQCHECKBOX1(hWnd AS long)
  reDIM Check(CheckIndex+1) AS QCHECKBOX
  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  token="ChkBox"+STR$(CheckIndex+1)
  Check(CheckIndex).Caption=token

  Check(CheckIndex).Parent=Forms(FormIndex)                     ' MUST set a valid parent first!
  IF hWnd<>Forms(FormIndex).Handle THEN
    SetParent(Check(CheckIndex).Handle,hWnd)                    ' Set to correct parent
  END IF
  tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
  ScreenToClient(hWnd,tPoint)
  Check(CheckIndex).Left=tPoint.x
  Check(CheckIndex).Top=tPoint.y
  Check(CheckIndex).Width=100
  Check(CheckIndex).Height=20
  CurrentObject=ObjectIndex

  ObjectType(CurrentObject)="QCHECKBOX"
  ObjTypeIndex(CurrentObject)=CheckIndex

  tstr=STR$(NewObjectID)+"|QCHECKBOX|"+STR$(Check(CheckIndex).Handle)+"|"+token+"|"+token+"|"+STR$(hWnd)+"~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(NewObjectID)
  PropertyFieldUpdate("Left",STR$(tPoint.x)) ',4)                    '
  PropertyFieldUpdate("Top",STR$(tPoint.y)) ',4)                     ' Update new properties in AddedObjectList..
  PropertyFieldUpdate("Caption",token) ',4)                          ' ..Width & Height defaults
  PropertyFieldUpdate("Parent",WhichParent(hWnd)) ',4)               '

  SelectionCombo.AddItems token+" [QCHECKBOX]"
  SelectionCombo.ItemIndex=CurrentObject


  UpdatePropGrid(CurrentObject)                                   ' Update String grid
  INC ObjectIndex: INC CheckIndex
END SUB

'*****************************************
SUB AddQRADIOBUTTON1(hWnd AS long)
  reDIM Radio(RadioIndex+1) AS QRADIOBUTTON
  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  token="RadioBtn"+STR$(RadioIndex+1)
  Radio(RadioIndex).Caption=token

  Radio(RadioIndex).Parent=Forms(FormIndex)                     ' MUST set a valid parent first!
  IF hWnd<>Forms(FormIndex).Handle THEN
    SetParent(Radio(RadioIndex).Handle,hWnd)                    ' Set to correct parent
  END IF
  tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
  ScreenToClient(hWnd,tPoint)
  Radio(RadioIndex).Left=tPoint.x
  Radio(RadioIndex).Top=tPoint.y
  Radio(RadioIndex).Width=100
  Radio(RadioIndex).Height=20
  CurrentObject=ObjectIndex

  ObjectType(CurrentObject)="QRADIOBUTTON"
  ObjTypeIndex(CurrentObject)=RadioIndex


  tstr=STR$(NewObjectID)+"|QRADIOBUTTON|"+STR$(Radio(RadioIndex).Handle)+"|"+token+"|"+token+"|"+STR$(hWnd)+"~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(NewObjectID)
  PropertyFieldUpdate("Left",STR$(tPoint.x)) ',4)                    '
  PropertyFieldUpdate("Top",STR$(tPoint.y)) ',4)                     ' Update new properties in AddedObjectList..
  PropertyFieldUpdate("Caption",token) ',4)                          ' ..Width & Height defaults
  PropertyFieldUpdate("Parent",WhichParent(hWnd)) ',4)               '

  SelectionCombo.AddItems token+" [QRADIOBUTTON]"
  SelectionCombo.ItemIndex=CurrentObject


  UpdatePropGrid(CurrentObject)                                   ' Update String grid
  INC ObjectIndex: INC RadioIndex
END SUB

'*****************************************
SUB AddQPANEL(hWnd AS long)
  call  AddClrString ("4098:AddQPANEL="+str$(AddQPANEL), clg, LogEdit)
  reDIM dPan(PanIndex+1) AS QPANEL
  DEFSTR tstr, token
  DIM tPoint AS PointAPI



  token="Panel"+STR$(PanIndex+1)
  dPan(PanIndex).Caption=token
  dPan(PanIndex).Width=150
  dPan(PanIndex).Height=100

  dPan(PanIndex).Parent=Forms(FormIndex)                        ' MUST set a valid parent first!


  IF hWnd<>Forms(FormIndex).Handle THEN
    SetParent(dPan(PanIndex).Handle,hWnd)                       ' Set to correct parent
  END IF

  call  AddClrString ("4122:dPan("+str$(PanIndex)+"Handle)="+str$(dPan(PanIndex).Handle), clp, LogEdit)


  tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
  ScreenToClient(hWnd,tPoint)
  dPan(PanIndex).Left=tPoint.x
  dPan(PanIndex).Top=tPoint.y
  call  AddClrString ("4116:PanIndex="+str$(PanIndex), clred, LogEdit)

  CurrentObject=ObjectIndex
  call  AddClrString ("4125:ObjectIndex="+str$(ObjectIndex), clred, LogEdit)

  ObjectType(CurrentObject)="QPANEL"
  ObjTypeIndex(CurrentObject)=PanIndex


  SelectionCombo.AddItems token+" [QPANEL]"
  SelectionCombo.ItemIndex=CurrentObject

  tstr=STR$(NewObjectID)+"|QPANEL|"+STR$(dPan(PanIndex).Handle)+"|"+token+"|"+token+"|"+STR$(hWnd)+"~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(NewObjectID)
  PropertyFieldUpdate("Left",STR$(tPoint.x)) ',4)                    '
  PropertyFieldUpdate("Top",STR$(tPoint.y)) ',4)                     ' Update new properties in AddedObjectList..
  PropertyFieldUpdate("Caption",token) ',4)                          ' ..Width & Height defaults
  PropertyFieldUpdate("Parent",WhichParent(hWnd)) ',4)               '



  UpdatePropGrid(CurrentObject)                                   ' Update String grid
  INC ObjectIndex: INC PanIndex
END SUB

'*****************************************
SUB AddQTABCONTROL1(hWnd AS long)
  reDIM TabCtrl(TabContIndex+1) AS QTABCONTROL
  reDIM BoxTab(TabContIndex+1) AS QPANEL                                ' QPanel as a container
  'DIM btn AS QBUTTON
  DEFLNG TabHandle
  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  BoxTab(TabContIndex).Width=150                                  ' Non-Default for a QTabControl...
  BoxTab(TabContIndex).Height=100                                 ' ...Re-sized for convenience
  BoxTab(TabContIndex).Borderstyle=0
  BoxTab(TabContIndex).BevelOuter=2
  token="TabCtrl"+STR$(TabContIndex+1)

  BoxTab(TabContIndex).Parent=Forms(FormIndex)                  ' MUST set a valid parent first!
  IF hWnd<>Forms(FormIndex).Handle THEN
    SetParent(BoxTab(TabContIndex).Handle,hWnd)                 ' Set to correct parent
  END IF
  tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
  ScreenToClient(hWnd,tPoint)
  BoxTab(TabContIndex).Left=tPoint.x
  BoxTab(TabContIndex).Top=tPoint.y

  TabCtrl(TabContIndex).Parent=BoxTab(TabContIndex)               '
  TabCtrl(TabContIndex).Align=alClient                            ' NB MUST do these AFTER container initialised
  TabCtrl(TabContIndex).AddTabs("T","A","B")
  '
  btn.Visible=False: btn.Parent=TabCtrl(TabContIndex)
  TabHandle=GetParent(btn.Handle)
  call  AddClrString ("4238:TabHandle="+str$(TabHandle), clp, LogEdit)
  DestroyWindow(btn.Handle)

  CurrentObject=ObjectIndex

  ObjectType(CurrentObject)="QTABCONTROL"
  ObjTypeIndex(CurrentObject)=TabContIndex


  tstr=STR$(NewObjectID)+"|QTABCONTROL|"+STR$(BoxTab(TabContIndex).Handle)+"|" _
  +token+"|"+token+"|"+STR$(hWnd)+"|"+STR$(TabHandle)+"~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(NewObjectID)
  PropertyFieldUpdate("Left",STR$(tPoint.x)) ',4)                    '
  PropertyFieldUpdate("Top",STR$(tPoint.y)) ',4)                     ' Update new properties in AddedObjectList..
  PropertyFieldUpdate("Parent",WhichParent(hWnd)) ',4)               '

  SelectionCombo.AddItems token+" [QTABCONTROL]"
  SelectionCombo.ItemIndex=CurrentObject


  UpdatePropGrid(CurrentObject)                                   ' Update String grid
  INC ObjectIndex: INC TabContIndex
END SUB

'*****************************************
' Minor problems with selecting this component at design time
SUB AddQCOMBOBOX1(hWnd AS long)
  reDIM Combo(ComboIndex+1) AS QCOMBOBOX
  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  token="Combo"+STR$(ComboIndex+1)
  Combo(ComboIndex).Text=token
  Combo(ComboIndex).Width=145
  Combo(ComboIndex).Parent=Forms(FormIndex)                     ' MUST set a valid parent first!
  IF hWnd<>Forms(FormIndex).Handle THEN
    SetParent(Combo(ComboIndex).Handle,hWnd)                    ' Set to correct parent
  END IF
  tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
  ScreenToClient(hWnd,tPoint)
  Combo(ComboIndex).Left=tPoint.x
  Combo(ComboIndex).Top=tPoint.y
  CurrentObject=ObjectIndex
  ObjectType(CurrentObject)="QCOMBOBOX"
  ObjTypeIndex(CurrentObject)=ComboIndex

  tstr=STR$(NewObjectID)+"|QCOMBOBOX|"+STR$(Combo(ComboIndex).Handle)+"|"+token+"|"+token+"|"+STR$(hWnd)+"~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(NewObjectID)
  PropertyFieldUpdate("Left",STR$(tPoint.x)) ',4)                    '
  PropertyFieldUpdate("Top",STR$(tPoint.y)) ',4)                     ' Update new properties in AddedObjectList..
  PropertyFieldUpdate("Text",token) ',4)                             '
  PropertyFieldUpdate("Parent",WhichParent(hWnd)) ',4)               '
  SelectionCombo.AddItems token+" [QCOMBOBOX]"
  SelectionCombo.ItemIndex=CurrentObject



  UpdatePropGrid(CurrentObject)                                   ' Update String grid
  INC ObjectIndex: INC ComboIndex
END SUB

'*****************************************
SUB AddQLISTBOX1(hWnd AS long)
  reDIM ListB(ListBIndex+1) AS QLISTBOX
  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  token="ListBox"+STR$(ListBIndex+1)
  ListB(ListBIndex).Width=120
  ListB(ListBIndex).Height=100
  ListB(ListBIndex).Parent=Forms(FormIndex)                     ' MUST set a valid parent first!
  IF hWnd<>Forms(FormIndex).Handle THEN
    SetParent(ListB(ListBIndex).Handle,hWnd)                    ' Set to correct parent
  END IF
  tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
  ScreenToClient(hWnd,tPoint)
  ListB(ListBIndex).Left=tPoint.x-2                               ' Fudge (-2) for correct positioning
  ListB(ListBIndex).Top=tPoint.y-2                                ' ditto
  ListB(ListBIndex).AddItems token
  CurrentObject=ObjectIndex
  ObjectType(CurrentObject)="QLISTBOX"
  ObjTypeIndex(CurrentObject)=ListBIndex

  tstr=STR$(NewObjectID)+"|QLISTBOX|"+STR$(ListB(ListBIndex).Handle)+"|"+token+"|"+token+"|"+STR$(hWnd)+"~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(NewObjectID)
  PropertyFieldUpdate("Left",STR$(tPoint.x)) ',4)                    '
  PropertyFieldUpdate("Top",STR$(tPoint.y)) ',4)                     ' Update new properties in AddedObjectList..
  PropertyFieldUpdate("Parent",WhichParent(hWnd)) ',4)               '

  SelectionCombo.AddItems token+" [QLISTBOX]"
  SelectionCombo.ItemIndex=CurrentObject


  UpdatePropGrid(CurrentObject)                                   ' Update String grid
  INC ObjectIndex: INC ListBIndex
END SUB

'*****************************************
SUB AddQGROUPBOX1(hWnd AS long)
  reDIM GrpBox(GrpBoxIndex+1) AS QGROUPBOX
  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  token="GrpBox"+STR$(GrpBoxIndex+1)
  GrpBox(GrpBoxIndex).Caption=token
  GrpBox(GrpBoxIndex).Width=150
  GrpBox(GrpBoxIndex).Height=100
  GrpBox(GrpBoxIndex).Parent=Forms(FormIndex)                   ' MUST set a valid parent first!
  IF hWnd<>Forms(FormIndex).Handle THEN
    SetParent(GrpBox(GrpBoxIndex).Handle,hWnd)                  ' Set to correct parent
  END IF
  tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
  ScreenToClient(hWnd,tPoint)
  GrpBox(GrpBoxIndex).Left=tPoint.x
  GrpBox(GrpBoxIndex).Top=tPoint.y
  CurrentObject=ObjectIndex
  ObjectType(CurrentObject)="QGROUPBOX"
  ObjTypeIndex(CurrentObject)=GrpBoxIndex

  tstr=STR$(NewObjectID)+"|QGROUPBOX|"+STR$(GrpBox(GrpBoxIndex).Handle)+"|"+token+"|"+token+"|"+STR$(hWnd)+"~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(NewObjectID)
  PropertyFieldUpdate("Left",STR$(tPoint.x)) ',4)                    '
  PropertyFieldUpdate("Top",STR$(tPoint.y)) ',4)                     ' Update new properties in AddedObjectList..
  PropertyFieldUpdate("Caption",token) ',4)                          '
  PropertyFieldUpdate("Parent",WhichParent(hWnd)) ',4)               '

  SelectionCombo.AddItems token+" [QGROUPBOX]"
  SelectionCombo.ItemIndex=CurrentObject



  UpdatePropGrid(CurrentObject)                                   ' Update String grid
  INC ObjectIndex: INC GrpBoxIndex
END SUB

'*****************************************
' An odd-one-out -> Qpanel placed inside to force scroll bars visible
SUB AddQSCROLLBOX1(hWnd AS long)
  reDIM ScrollB(ScrollBIndex+1) AS QSCROLLBOX
  reDIM BoxInner(ScrollBIndex+1) AS QPANEL                              ' For effect - force scrollbars visible
  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  ScrollB(ScrollBIndex).Width=150                                 ' Force size of ScrollBox
  ScrollB(ScrollBIndex).Height=100
  BoxInner(ScrollBIndex).Width=500                                ' Force scrollbars visible
  BoxInner(ScrollBIndex).Height=500

  token="ScrlBox"+STR$(ScrollBIndex+1)
  ScrollB(ScrollBIndex).Parent=Forms(FormIndex)                 ' MUST set a valid parent first!
  IF hWnd<>Forms(FormIndex).Handle THEN
    SetParent(ScrollB(ScrollBIndex).Handle,hWnd)                ' Set to correct parent
  END IF
  tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
  ScreenToClient(hWnd,tPoint)
  BoxInner(ScrollBIndex).Parent=ScrollB(ScrollBIndex)
  BoxInner(ScrollBIndex).Enabled=False                            ' Don't capture mouse clicks!
  ScrollB(ScrollBIndex).Left=tPoint.x-2                           ' Fudge for correct positioning
  ScrollB(ScrollBIndex).Top=tPoint.y-2                            ' ditto
  CurrentObject=ObjectIndex
  ObjectType(CurrentObject)="QSCROLLBOX"
  ObjTypeIndex(CurrentObject)=ScrollBIndex

  tstr=STR$(NewObjectID)+"|QSCROLLBOX|"+STR$(ScrollB(ScrollBIndex).Handle)+"|"+token+"|"+token+"|"+STR$(hWnd)+"~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(NewObjectID)
  PropertyFieldUpdate("Left",STR$(tPoint.x)) ',4)                    '
  PropertyFieldUpdate("Top",STR$(tPoint.y)) ',4)                     ' Update new properties in AddedObjectList..
  PropertyFieldUpdate("Parent",WhichParent(hWnd)) ',4)               '

  SelectionCombo.AddItems token+" [QSCROLLBOX]"
  SelectionCombo.ItemIndex=CurrentObject



  UpdatePropGrid(CurrentObject)                                   ' Update String grid
  INC ObjectIndex: INC ScrollBIndex
END SUB

'*****************************************
SUB AddQSCROLLBAR1(hWnd AS long)
  reDIM ScrollBar(ScrllBarIndex+1) AS QSCROLLBAR
  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  token="ScrlBar"+STR$(ScrllBarIndex+1)
  ScrollBar(ScrllBarIndex).Width=100
  ScrollBar(ScrllBarIndex).Height=20
  ScrollBar(ScrllBarIndex).Parent=Forms(FormIndex)              ' MUST set a valid parent first!
  IF hWnd<>Forms(FormIndex).Handle THEN
    SetParent(ScrollBar(ScrllBarIndex).Handle,hWnd)             ' Set to correct parent
  END IF
  tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
  ScreenToClient(hWnd,tPoint)
  ScrollBar(ScrllBarIndex).Left=tPoint.x
  ScrollBar(ScrllBarIndex).Top=tPoint.y
  CurrentObject=ObjectIndex
  ObjectType(CurrentObject)="QSCROLLBAR"
  ObjTypeIndex(CurrentObject)=ScrllBarIndex


  tstr=STR$(NewObjectID)+"|QSCROLLBAR|"+STR$(ScrollBar(ScrllBarIndex).Handle)+"|"+token+"|"+token+"|"+STR$(hWnd)+"~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(NewObjectID)
  PropertyFieldUpdate("Left",STR$(tPoint.x)) ',4)                    '
  PropertyFieldUpdate("Top",STR$(tPoint.y)) ',4)                     ' Update new properties in AddedObjectList..
  PropertyFieldUpdate("Parent",WhichParent(hWnd)) ',4)               '

  SelectionCombo.AddItems token+" [QSCROLLBAR]"
  SelectionCombo.ItemIndex=CurrentObject



  UpdatePropGrid(CurrentObject)                                   ' Update String grid
  INC ObjectIndex: INC ScrllBarIndex
END SUB

'*****************************************
'!!! Arrays of StringGrid has problems - using QListView instead!!
SUB AddQSTRINGGRID1(hWnd AS long)
  reDIM StrGrid(StringGIndex+1) AS QLISTVIEW
  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  token="StringGrid"+STR$(StringGIndex+1)
  StrGrid(StringGIndex).Width=150
  StrGrid(StringGIndex).Height=100
  StrGrid(StringGIndex).Parent=Forms(FormIndex)                 ' MUST set a valid parent first!
  IF hWnd<>Forms(FormIndex).Handle THEN
    SetParent(StrGrid(StringGIndex).Handle,hWnd)                ' Set to correct parent
  END IF
  tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
  ScreenToClient(hWnd,tPoint)
  StrGrid(StringGIndex).Left=tPoint.x-2                           ' Fudge to correct positioning
  StrGrid(StringGIndex).Top=tPoint.y-2                            ' ditto


  StrGrid(StringGIndex).GridLines=True                            '
  StrGrid(StringGIndex).ViewStyle=vsReport                        ' Some visual presets
  StrGrid(StringGIndex).AddColumns token,""                       '
  StrGrid(StringGIndex).Column(0).Width=74
  StrGrid(StringGIndex).Column(1).Width=74
  CurrentObject=ObjectIndex
  ObjectType(CurrentObject)="QSTRINGGRID"
  ObjTypeIndex(CurrentObject)=StringGIndex

  tstr=STR$(NewObjectID)+"|QSTRINGGRID|"+STR$(StrGrid(StringGIndex).Handle)+"|"+token+"|"+token+"|"+STR$(hWnd)+"~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(NewObjectID)
  PropertyFieldUpdate("Left",STR$(tPoint.x)) ',4)                    '
  PropertyFieldUpdate("Top",STR$(tPoint.y)) ',4)                     ' Update new properties in AddedObjectList..
  PropertyFieldUpdate("Parent",WhichParent(hWnd)) ',4)               '

  SelectionCombo.AddItems token+" [QSTRINGGRID]"
  SelectionCombo.ItemIndex=CurrentObject


  UpdatePropGrid(CurrentObject)                                   ' Update String grid
  INC ObjectIndex: INC StringGIndex
END SUB

'*****************************************
SUB AddQLISTVIEW1(hWnd AS long)
  reDIM ListView(ListVIndex+1) AS QLISTVIEW
  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  token="ListView"+STR$(ListVIndex+1)
  ListView(ListVIndex).Width=150
  ListView(ListVIndex).Height=100
  ListView(ListVIndex).Parent=Forms(FormIndex)                  ' MUST set a valid parent first!
  IF hWnd<>Forms(FormIndex).Handle THEN
    SetParent(ListView(ListVIndex).Handle,hWnd)                 ' Set to correct parent
  END IF
  tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
  ScreenToClient(hWnd,tPoint)
  ListView(ListVIndex).Left=tPoint.x-2                            ' Fudge fix positioning
  ListView(ListVIndex).Top=tPoint.y-2                             ' ditto

  ListView(ListVIndex).GridLines=True                             '
  ListView(ListVIndex).ViewStyle=vsReport                         ' Some visual presets
  ListView(ListVIndex).AddColumns token,""                        '
  ListView(ListVIndex).Column(0).Width=74
  ListView(ListVIndex).Column(1).Width=74
  CurrentObject=ObjectIndex
  ObjectType(CurrentObject)="QLISTVIEW"
  ObjTypeIndex(CurrentObject)=ListVIndex

  tstr=STR$(NewObjectID)+"|QLISTVIEW|"+STR$(ListView(ListVIndex).Handle)+"|"+token+"|"+token+"|"+STR$(hWnd)+"~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(NewObjectID)
  PropertyFieldUpdate("Left",STR$(tPoint.x)) ',4)                    '
  PropertyFieldUpdate("Top",STR$(tPoint.y)) ',4)                     ' Update new properties in AddedObjectList..
  PropertyFieldUpdate("Parent",WhichParent(hWnd)) ',4)               '

  SelectionCombo.AddItems token+" [QLISTVIEW]"
  SelectionCombo.ItemIndex=CurrentObject



  UpdatePropGrid(CurrentObject)                                   ' Update String grid
  INC ObjectIndex: INC ListVIndex
END SUB

'*****************************************
' Problems with this so using a QPANEL container
SUB AddQHEADER1(hWnd AS long)
  DIM Headr(HeadIndex+1) AS QHEADER
  DIM BoxHeadr(HeadIndex+1) AS QPANEL
  DEFSTR tstr, token
  DIM rect AS QRECT
  DIM tPoint AS PointAPI

  IF ParentHasObject(hWnd,NewObjectID,"QHEADER") THEN EXIT SUB              ' ONLY 1 object per parent allowed!

  token="Header"+STR$(HeadIndex+1)
  BoxHeadr(HeadIndex).Align=alTop
  BoxHeadr(HeadIndex).Height=17
  BoxHeadr(HeadIndex).BevelOuter=2
  BoxHeadr(HeadIndex).Parent=Forms(FormIndex)                   ' MUST set a valid parent first!
  IF hWnd<>Forms(FormIndex).Handle THEN
    SetParent(BoxHeadr(HeadIndex).Handle,hWnd)                  ' Set to correct parent
  END IF
  Headr(HeadIndex).Parent=BoxHeadr(HeadIndex)
  Headr(HeadIndex).Align=alClient
  Headr(HeadIndex).AddSections "Hdr1","Hdr2","Hdr3"
  Headr(HeadIndex).Enabled=False
  CurrentObject=ObjectIndex
  ObjectType(CurrentObject)="QHEADER"
  ObjTypeIndex(CurrentObject)=HeadIndex


  tstr=STR$(NewObjectID)+"|QHEADER|"+STR$(BoxHeadr(HeadIndex).Handle)+"|"+token+"|"+token+"|"+STR$(hWnd)+"~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(NewObjectID)
  PropertyFieldUpdate("Parent",WhichParent(hWnd)) ',4)

  SelectionCombo.AddItems token+" [QHEADER]"
  SelectionCombo.ItemIndex=CurrentObject
  UpdatePropGrid(CurrentObject)                                   ' Update String grid
  INC ObjectIndex: INC HeadIndex
END SUB

'*****************************************
SUB AddQSTATUSBAR1(hWnd AS long)
  reDIM StatBar(StatIndex+1) AS QSTATUSBAR
  reDIM BoxStat(StatIndex+1) AS QPANEL
  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  'IF ParentHasObject(hWnd,NewObjectID) THEN EXIT SUB              ' ONLY 1 object per parent allowed!

  token="Status"+STR$(StatIndex+1)
  BoxStat(StatIndex).Align=alBottom
  BoxStat(StatIndex).Height=19
  BoxStat(StatIndex).BevelOuter=2
  BoxStat(StatIndex).Parent=Forms(FormIndex)                    ' MUST set a valid parent first!
  IF hWnd<>Forms(FormIndex).Handle THEN
    SetParent(BoxStat(StatIndex).Handle,hWnd)                   ' Set to correct parent
  END IF
  StatBar(StatIndex).Parent=BoxStat(StatIndex)
  StatBar(StatIndex).Align=alClient
  StatBar(StatIndex).SimplePanel=True
  StatBar(StatIndex).SimpleText=token
  StatBar(StatIndex).Enabled=False
  CurrentObject=ObjectIndex

  ObjectType(CurrentObject)="QSTATUSBAR"
  ObjTypeIndex(CurrentObject)=StatIndex

  tstr=STR$(NewObjectID)+"|QSTATUSBAR|"+STR$(BoxStat(StatIndex).Handle)+"|"+token+"|"+token+"|"+STR$(hWnd)+"~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(NewObjectID)
  PropertyFieldUpdate("Parent",WhichParent(hWnd)) ',4)

  SelectionCombo.AddItems token+" [QSTATUSBAR]"
  SelectionCombo.ItemIndex=CurrentObject
  UpdatePropGrid(CurrentObject)                                   ' Update String grid
  INC ObjectIndex: INC StatIndex
END SUB

'*****************************************
SUB AddQDIRTREE1(hWnd AS long)
  DIM DirTree AS QDIRTREE
  DIM BoxDTree AS QPANEL
  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  IF DirTIndex>0 THEN                                             ' ONLY 1 allowed!
    MessageBox("Internally limited to one instance only!","RapidFRM "+VER,&h30)
    EXIT SUB
  END IF

  INC DirTIndex
  token="DirTree"+STR$(DirTIndex)
  BoxDTree.Width=150
  BoxDTree.Height=150
  BoxDTree.BevelOuter=2
  BoxDTree.Parent=Forms(FormIndex)                              ' MUST set a valid parent first!
  IF hWnd<>Forms(FormIndex).Handle THEN
    SetParent(BoxDTree.Handle,hWnd)                             ' Set to correct parent
  END IF
  tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
  ScreenToClient(hWnd,tPoint)
  BoxDTree.Left=tPoint.x: BoxDTree.Top=tPoint.y
  DirTree.Parent=BoxDTree: DirTree.Align=alClient: DirTree.Enabled=False
  CurrentObject=ObjectIndex

  ObjectType(CurrentObject)="QDIRTREE"
  ObjTypeIndex(CurrentObject)=DirTIndex

  tstr=STR$(NewObjectID)+"|QDIRTREE|"+STR$(BoxDTree.Handle)+"|"+token+"|"+token+"|"+STR$(hWnd)+"~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(NewObjectID)
  PropertyFieldUpdate("Left",STR$(tPoint.x)) ',4)                    '
  PropertyFieldUpdate("Top",STR$(tPoint.y)) ',4)                     ' Update new properties in AddedObjectList..
  PropertyFieldUpdate("Parent",WhichParent(hWnd)) ',4)               '

  SelectionCombo.AddItems token+" [QDIRTREE]"
  SelectionCombo.ItemIndex=CurrentObject
  UpdatePropGrid(CurrentObject)                                   ' Update String grid
  INC ObjectIndex
END SUB

'*****************************************
SUB AddQFILELISTBOX1(hWnd AS long)
  reDIM dFileL(FileLindex+1) AS QFILELISTBOX
  reDIM BoxFile(FileLindex+1) AS QPANEL
  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  token="FileListBox"+ STR$(FileLindex+1)
  BoxFile(FileLindex).Width=150
  BoxFile(FileLindex).Height=150
  BoxFile(FileLindex).BevelOuter=2
  BoxFile(FileLindex).Parent=Forms(FormIndex)                   ' MUST set a valid parent first!
  IF hWnd<>Forms(FormIndex).Handle THEN
    SetParent(BoxFile(FileLindex).Handle,hWnd)                  ' Set to correct parent
  END IF
  tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
  ScreenToClient(hWnd,tPoint)
  BoxFile(FileLindex).Left=tPoint.x
  BoxFile(FileLindex).Top=tPoint.y
  dFileL(FileLindex).Parent=BoxFile(FileLindex)
  dFileL(FileLindex).Align=alClient
  dFileL(FileLindex).Enabled=False
  CurrentObject=ObjectIndex

  ObjectType(CurrentObject)="QFILELISTBOX"
  ObjTypeIndex(CurrentObject)=FileLindex

  tstr=STR$(NewObjectID)+"|QFILELISTBOX|"+STR$(BoxFile(FileLindex).Handle)+"|"+token+"|"+token+"|"+STR$(hWnd)+"~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(NewObjectID)
  PropertyFieldUpdate("Left",STR$(tPoint.x)) ',4)                    '
  PropertyFieldUpdate("Top",STR$(tPoint.y)) ',4)                     ' Update new properties in AddedObjectList..
  PropertyFieldUpdate("Parent",WhichParent(hWnd)) ',4)               '

  SelectionCombo.AddItems token+" [QFILELISTBOX]"
  SelectionCombo.ItemIndex=CurrentObject
  UpdatePropGrid(CurrentObject)                                   ' Update String grid
  INC ObjectIndex: INC FileLindex
END SUB

'*****************************************
SUB AddQGAUGE1(hWnd AS long)                                         ' Fudge using QPANEL
  DIM dGauge(GaugeIndex+1) AS QGAUGE
  DIM panGauge(GaugeIndex+1) AS QPANEL
  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  token="Gauge"+STR$(GaugeIndex+1)
  panGauge(GaugeIndex).Width=100
  panGauge(GaugeIndex).Height=25
  panGauge(GaugeIndex).BevelOuter=2
  panGauge(GaugeIndex).Parent=Forms(FormIndex)                  ' MUST set a valid parent first!
  IF hWnd<>Forms(FormIndex).Handle THEN
    SetParent(panGauge(GaugeIndex).Handle,hWnd)                 ' Set to correct parent
  END IF
  tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
  ScreenToClient(hWnd,tPoint)
  panGauge(GaugeIndex).Left=tPoint.x
  panGauge(GaugeIndex).Top=tPoint.y
  dGauge(GaugeIndex).Parent=panGauge(GaugeIndex)
  dGauge(GaugeIndex).Align=alClient
  dGauge(GaugeIndex).Position=75
  CurrentObject=ObjectIndex

  ObjectType(CurrentObject)="QGAUGE"
  ObjTypeIndex(CurrentObject)=GaugeIndex



  tstr=STR$(NewObjectID)+"|QGAUGE|"+STR$(panGauge(GaugeIndex).Handle)+"|"+token+"|"+token+"|"+STR$(hWnd)+"~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(NewObjectID)
  PropertyFieldUpdate("Left",STR$(tPoint.x)) ',4)                    '
  PropertyFieldUpdate("Top",STR$(tPoint.y)) ',4)                     ' Update new properties in AddedObjectList..
  PropertyFieldUpdate("Parent",WhichParent(hWnd)) ',4)               '

  SelectionCombo.AddItems token+" [QGAUGE]"
  SelectionCombo.ItemIndex=CurrentObject
  UpdatePropGrid(CurrentObject)                                   ' Update String grid
  INC ObjectIndex: INC GaugeIndex
END SUB

'*****************************************
SUB AddQTRACKBAR1(hWnd AS long)
  reDIM dTrackBar(TrackBIndex+1) AS QTRACKBAR
  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  token="TrackBar"+STR$(TrackBIndex+1)
  dTrackBar(TrackBIndex).Width=150
  dTrackBar(TrackBIndex).Height=45
  dTrackBar(TrackBIndex).Parent=Forms(FormIndex)                ' MUST set a valid parent first!
  IF hWnd<>Forms(FormIndex).Handle THEN
    SetParent(dTrackBar(TrackBIndex).Handle,hWnd)               ' Set to correct parent
  END IF
  tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
  ScreenToClient(hWnd,tPoint)
  dTrackBar(TrackBIndex).Left=tPoint.x
  dTrackBar(TrackBIndex).Top=tPoint.y
  dTrackBar(TrackBIndex).Max=20
  dTrackBar(TrackBIndex).Position=15
  CurrentObject=ObjectIndex

  ObjectType(CurrentObject)="QTRACKBAR"
  ObjTypeIndex(CurrentObject)=TrackBIndex

  tstr=STR$(NewObjectID)+"|QTRACKBAR|"+STR$(dTrackBar(TrackBIndex).Handle)+"|"+token+"|"+token+"|"+STR$(hWnd)+"~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(NewObjectID)
  PropertyFieldUpdate("Left",STR$(tPoint.x)) ',4)                    '
  PropertyFieldUpdate("Top",STR$(tPoint.y)) ',4)                     ' Update new properties in AddedObjectList..
  PropertyFieldUpdate("Parent",WhichParent(hWnd)) ',4)               '

  SelectionCombo.AddItems token+" [QTRACKBAR]"
  SelectionCombo.ItemIndex=CurrentObject
  UpdatePropGrid(CurrentObject)                                   ' Update String grid
  INC ObjectIndex: INC TrackBIndex
END SUB

' Defaults to a "dummy" vertical splitter
'*****************************************
SUB AddQSPLITTER1(hWnd AS long)                                      ' Fudge using a QPanel
  reDIM panSplit(SplitIndex+1) AS QPANEL
  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  hWnd=Forms(FormIndex).Handle                                  ' FORCE to FormIndex!
  'IF ParentHasObject(hWnd,NewObjectID) THEN EXIT SUB              ' ONLY 1 object parent allowed!

  token="Split"+STR$(SplitIndex+1)
  panSplit(SplitIndex).Parent=Forms(FormIndex)                  ' Set parent property to form
  tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
  ScreenToClient(hWnd,tPoint)
  panSplit(SplitIndex).Left=tPoint.x
  panSplit(SplitIndex).Top=0
  panSplit(SplitIndex).Height=Forms(FormIndex).ClientHeight
  panSplit(SplitIndex).Width=3
  panSplit(SplitIndex).BorderStyle=1
  panSplit(SplitIndex).Cursor=crHSplit
  CurrentObject=ObjectIndex

  ObjectType(CurrentObject)="QSPLITTER"
  ObjTypeIndex(CurrentObject)=SplitIndex


  tstr=STR$(NewObjectID)+"|QSPLITTER|"+STR$(panSplit(SplitIndex).Handle)+"|"+token+"|"+token+"|"+STR$(hWnd)+"~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(NewObjectID)
  PropertyFieldUpdate("Left",STR$(tPoint.x)) ',4)                    '
  PropertyFieldUpdate("Top","0") ',4)                                ' Update new properties in AddedObjectList..
  PropertyFieldUpdate("Width","3") ',4)                              '
  PropertyFieldUpdate("Height",STR$(Forms(FormIndex).ClientHeight)) ',4)    '
  PropertyFieldUpdate("Parent",WhichParent(hWnd)) ',4)               '

  SelectionCombo.AddItems token+" [QSPLITTER]"
  SelectionCombo.ItemIndex=CurrentObject
  UpdatePropGrid(CurrentObject)                                   ' Update String grid
  INC ObjectIndex: INC SplitIndex
END SUB

'*****************************************
SUB AddQTREEVIEW1(hWnd AS long)
  DIM TreeView AS QTREEVIEW
  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  IF TreeVIndex>0 THEN                                            ' ONLY 1 allowed!
    MessageBox("Only one instance allowed!","RapidFRM "+VER,&h30)
    EXIT SUB
  END IF
  INC TreeVIndex

  token="TreeView"+STR$(TreeVIndex)
  TreeView.Width=120
  TreeView.Height=100
  TreeView.Parent=Forms(FormIndex)                              ' MUST set a valid parent first!
  IF hWnd<>Forms(FormIndex).Handle THEN
    SetParent(TreeView.Handle,hWnd)                             ' Set to correct parent
  END IF
  tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
  ScreenToClient(hWnd,tPoint)
  TreeView.Left=tPoint.x-2
  TreeView.Top=tPoint.y-2
  TreeView.ReadOnly=True
  TreeView.AddItems "1","2","3"
  TreeView.AddChildItems 0, "Child A", "Child B", "Child C"
  TreeView.AddChildItems 4, "Child X", "Child Y", "Child Z"
  CurrentObject=ObjectIndex

  ObjectType(CurrentObject)="QTREEVIEW"
  ObjTypeIndex(CurrentObject)=TreeVIndex


  tstr=STR$(NewObjectID)+"|QTREEVIEW|"+STR$(TreeView.Handle)+"|"+token+"|"+token+"|"+STR$(hWnd)+"~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(NewObjectID)
  PropertyFieldUpdate("Left",STR$(tPoint.x)) ',4)                    '
  PropertyFieldUpdate("Top",STR$(tPoint.y)) ',4)                     ' Update new properties in AddedObjectList..
  PropertyFieldUpdate("Parent",WhichParent(hWnd)) ',4)               '

  SelectionCombo.AddItems token+" [QTREEVIEW]"
  SelectionCombo.ItemIndex=CurrentObject
  UpdatePropGrid(CurrentObject)                                   ' Update String grid
  INC ObjectIndex
END SUB

' FIXME: Problem with arrays of QOutLine
'*****************************************
SUB AddQOUTLINE1(hWnd AS long)
  DIM frmOutLine AS QOUTLINE
  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  IF OutLnIndex>0 THEN                                            ' ONLY 1 allowed!
    MessageBox("Only one instance allowed!","RapidFRM "+VER,&h30)
    EXIT SUB
  END IF
  INC OutLnIndex

  token="OutLine"+STR$(OutLnIndex)
  frmOutLine.Width=120
  frmOutLine.Height=100
  frmOutLine.Parent=Forms(FormIndex)                            ' MUST set a valid parent first!
  IF hWnd<>Forms(FormIndex).Handle THEN
    SetParent(frmOutLine.Handle,hWnd)                           ' Set to correct parent
  END IF
  tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
  ScreenToClient(hWnd,tPoint)
  frmOutLine.Left=tPoint.x-2
  frmOutLine.Top=tPoint.y-2
  frmOutLine.AddLines token,"Child1","Child2"
  frmOutLine.AddLines "Parent2","Child1","Child2"
  CurrentObject=ObjectIndex

  ObjectType(CurrentObject)="QOUTLINE"
  ObjTypeIndex(CurrentObject)=OutLnIndex

  tstr=STR$(NewObjectID)+"|QOUTLINE|"+STR$(frmOutLine.Handle)+"|"+token+"|"+token+"|"+STR$(hWnd)+"~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(NewObjectID)
  PropertyFieldUpdate("Left",STR$(tPoint.x)) ',4)                    '
  PropertyFieldUpdate("Top",STR$(tPoint.y)) ',4)                     ' Update new properties in AddedObjectList..
  PropertyFieldUpdate("Parent",WhichParent(hWnd)) ',4)               '

  SelectionCombo.AddItems token+" [QOUTLINE]"
  SelectionCombo.ItemIndex=CurrentObject
  UpdatePropGrid(CurrentObject)                                   ' Update String grid
  INC ObjectIndex
END SUB

'*****************************************
SUB AddQOLECONTAINER1(hWnd AS long)                                  ' Fudge using QPANEL
  reDIM oleContainer(OLEContIndex+1) AS QPANEL
  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  token="OLEContainer"+STR$(OLEContIndex+1)
  oleContainer(OLEContIndex).Width=100
  oleContainer(OLEContIndex).Height=100
  oleContainer(OLEContIndex).BevelOuter=2
  oleContainer(OLEContIndex).Parent=Forms(FormIndex)            ' MUST set a valid parent first!
  IF hWnd<>Forms(FormIndex).Handle THEN
    SetParent(oleContainer(OLEContIndex).Handle,hWnd)           ' Set to correct parent
  END IF
  tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
  ScreenToClient(hWnd,tPoint)
  oleContainer(OLEContIndex).Left=tPoint.x
  oleContainer(OLEContIndex).Top=tPoint.y
  oleContainer(OLEContIndex).Caption=token
  CurrentObject=ObjectIndex

  ObjectType(CurrentObject)="QOLECONTAINER"
  ObjTypeIndex(CurrentObject)=OLEContIndex


  tstr=STR$(NewObjectID)+"|QOLECONTAINER|"+STR$(oleContainer(OLEContIndex).Handle)+"|"+token+"|"+token+"|"+STR$(hWnd)+"~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(NewObjectID)
  PropertyFieldUpdate("Left",STR$(tPoint.x)) ',4)                    '
  PropertyFieldUpdate("Top",STR$(tPoint.y)) ',4)                     ' Update new properties in AddedObjectList..
  PropertyFieldUpdate("Caption",token) ',4)                          '
  PropertyFieldUpdate("Parent",WhichParent(hWnd)) ',4)               '

  SelectionCombo.AddItems token+" [QOLECONTAINER]"
  SelectionCombo.ItemIndex=CurrentObject
  UpdatePropGrid(CurrentObject)                                   ' Update String grid
  INC ObjectIndex: INC OLEContIndex
END SUB

'*****************************************
SUB AddQCANVAS1(hWnd AS long)                                        ' Fudge using QPANEL
  reDIM panCanv(CanvasIndex+1) AS QPANEL
  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  token="Canvas"+STR$(CanvasIndex+1)
  panCanv(CanvasIndex).Width=100
  panCanv(CanvasIndex).Height=100
  panCanv(CanvasIndex).Parent=Forms(FormIndex)                  ' MUST set a valid parent first!
  IF hWnd<>Forms(FormIndex).Handle THEN
    SetParent(panCanv(CanvasIndex).Handle,hWnd)                 ' Set to correct parent
  END IF
  tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
  ScreenToClient(hWnd,tPoint)
  panCanv(CanvasIndex).Left=tPoint.x
  panCanv(CanvasIndex).Top=tPoint.y
  panCanv(CanvasIndex).Caption=token
  CurrentObject=ObjectIndex
  ObjectType(CurrentObject)="QCANVAS"
  ObjTypeIndex(CurrentObject)=CanvasIndex


  tstr=STR$(NewObjectID)+"|QCANVAS|"+STR$(panCanv(CanvasIndex).Handle)+"|"+token+"|"+token+"|"+STR$(hWnd)+"~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(NewObjectID)
  PropertyFieldUpdate("Left",STR$(tPoint.x)) ',4)                    '
  PropertyFieldUpdate("Top",STR$(tPoint.y)) ',4)                     ' Update new properties in AddedObjectList..
  PropertyFieldUpdate("Caption",token) ',4)                          '
  PropertyFieldUpdate("Parent",WhichParent(hWnd)) ',4)               '

  SelectionCombo.AddItems token+" [QCANVAS]"
  SelectionCombo.ItemIndex=CurrentObject
  UpdatePropGrid(CurrentObject)                                   ' Update String grid
  INC ObjectIndex: INC CanvasIndex
END SUB

'*****************************************
SUB AddQIMAGE1(hWnd AS long)                                         ' Fudge using QPANEL
  reDIM panImage(ImageIndex+1) AS QPANEL
  DEFSTR tstr, token
  DIM tPoint AS PointAPI

  token="Image"+STR$(ImageIndex+1)
  panImage(ImageIndex).Width=100
  panImage(ImageIndex).Height=100
  panImage(ImageIndex).BevelOuter=2
  panImage(ImageIndex).Color=&hffffff
  panImage(ImageIndex).Parent=Forms(FormIndex)                  ' MUST set a valid parent first!
  IF hWnd<>Forms(FormIndex).Handle THEN
    SetParent(panImage(ImageIndex).Handle,hWnd)                 ' Set to correct parent
  END IF
  tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
  ScreenToClient(hWnd,tPoint)
  panImage(ImageIndex).Left=tPoint.x
  panImage(ImageIndex).Top=tPoint.y
  panImage(ImageIndex).Caption=token
  CurrentObject=ObjectIndex

  ObjectType(CurrentObject)="QIMAGE"
  ObjTypeIndex(CurrentObject)=ImageIndex

  tstr=STR$(NewObjectID)+"|QIMAGE|"+STR$(panImage(ImageIndex).Handle)+"|"+token+"|"+token+"|"+STR$(hWnd)+"~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(NewObjectID)
  PropertyFieldUpdate("Left",STR$(tPoint.x)) ',4)                    '
  PropertyFieldUpdate("Top",STR$(tPoint.y)) ',4)                     ' Update new properties in AddedObjectList..
  PropertyFieldUpdate("Caption",token) ',4)                          '
  PropertyFieldUpdate("Parent",WhichParent(hWnd)) ',4)               '

  SelectionCombo.AddItems token+" [QIMAGE]"
  SelectionCombo.ItemIndex=CurrentObject
  UpdatePropGrid(CurrentObject)                                   ' Update String grid
  INC ObjectIndex: INC ImageIndex
END SUB

' Non-visible components
'*****************************************
SUB AddNonVisible1(hWnd AS long)
  DIM dNonVis(NonVIndex+1) AS QBUTTON
  DEFINT i, ObjIdx
  DEFSTR tstr, ObjType, ObjName

  SELECT CASE NewObjectID
  CASE Q_BITMAP
    INC BmpIndex: ObjIdx=BmpIndex
    ObjName="Bitmap"+STR$(ObjIdx): ObjType="QBITMAP"
  CASE Q_IMAGELIST
    INC ImgListIndex: ObjIdx=ImgListIndex
    ObjName="ImageList"+STR$(ObjIdx): ObjType="QIMAGELIST"
  CASE Q_STRINGLIST
    INC StrListIndex: ObjIdx=StrListIndex
    ObjName="StringList"+STR$(ObjIdx): ObjType="QSTRINGLIST"
  CASE Q_TIMER
    INC TimerIndex: ObjIdx=TimerIndex
    ObjName="Timer"+STR$(ObjIdx): ObjType="QTIMER"
  CASE Q_SOCKET
    INC SockIndex: ObjIdx=SockIndex
    ObjName="Socket"+STR$(ObjIdx): ObjType="QSOCKET"
  CASE Q_FILESTREAM
    INC FStreamIndex: ObjIdx=FStreamIndex
    ObjName="FileStream"+STR$(ObjIdx): ObjType="QFILESTREAM"
  CASE Q_MEMORYSTREAM
    INC MStreamIndex: ObjIdx=MStreamIndex
    ObjName="MemStream"+STR$(ObjIdx): ObjType="QMEMORYSTREAM"
  CASE Q_FONT
    INC FontIndex: ObjIdx=FontIndex
    ObjName="Font"+STR$(ObjIdx): ObjType="QFONT"
  CASE Q_MYSQL
    INC SQLIndex: ObjIdx=SQLIndex
    ObjName="MySQL"+STR$(ObjIdx): ObjType="QMYSQL"
  CASE Q_OLEOBJECT
    INC OleObjIndex: ObjIdx=OleObjIndex
    ObjName="OLEObject"+STR$(ObjIdx): ObjType="QOLEOBJECT"
  CASE Q_REGISTRY
    INC RegIndex: ObjIdx=RegIndex
    ObjName="Registry"+STR$(ObjIdx): ObjType="QREGISTRY"
  CASE Q_OPENDIALOG
    '            IF OpenDlgIndex>0 THEN EXIT SUB                            ' One instance only?
    INC OpenDlgIndex: ObjIdx=OpenDlgIndex
    ObjName="OpenDialog"+STR$(ObjIdx): ObjType="QOPENDIALOG"
  CASE Q_SAVEDIALOG
    '            IF SaveDlgIndex>0 THEN EXIT SUB
    INC SaveDlgIndex: ObjIdx=SaveDlgIndex
    ObjName="SaveDialog"+STR$(ObjIdx): ObjType="QSAVEDIALOG"
  CASE Q_FONTDIALOG
    '            IF FontDlgIndex>0 THEN EXIT SUB
    INC FontDlgIndex: ObjIdx=FontDlgIndex
    ObjName="FontDialog"+STR$(ObjIdx): ObjType="QFONTDIALOG"
  CASE Q_COLORDIALOG
    '            IF ColorDlgIndex>0 THEN EXIT SUB
    INC ColorDlgIndex: ObjIdx=ColorDlgIndex
    ObjName="ColorDialog"+STR$(ObjIdx): ObjType="QCOLORDIALOG"
  CASE Q_DXTIMER
    '            IF DXTimerIdx>0 THEN EXIT SUB
    INC DXTimerIdx: ObjIdx=DXTimerIdx
    ObjName="DXTimer"+STR$(ObjIdx): ObjType="QDXTIMER"
  CASE Q_DXSOUND
    '            IF DXSoundIdx>0 THEN EXIT SUB
    INC DXSoundIdx: ObjIdx=DXSoundIdx
    ObjName="DXSound"+STR$(ObjIdx): ObjType="QDXSOUND"
  CASE Q_DXSCREEN
    '            IF DXScreenIdx>0 THEN EXIT SUB
    INC DXScreenIdx: ObjIdx=DXScreenIdx
    ObjName="DXScreen"+STR$(ObjIdx): ObjType="QDXSCREEN"
  CASE Q_DXIMAGELIST
    '            IF DXImgListIdx>0 THEN EXIT SUB
    INC DXImgListIdx: ObjIdx=DXImgListIdx
    ObjName="DXImgList"+STR$(ObjIdx): ObjType="QDXIMAGELIST"
  CASE Q_D3DFACE
    '            IF D3DFaceIdx>0 THEN EXIT SUB
    INC D3DFaceIdx: ObjIdx=D3DFaceIdx
    ObjName="D3DFace"+STR$(ObjIdx): ObjType="QD3DFACE"
  CASE Q_D3DMESHBUILDER
    '            IF MeshBuilderIdx>0 THEN EXIT SUB
    INC MeshBuilderIdx: ObjIdx=MeshBuilderIdx
    ObjName="MeshBuilder"+STR$(ObjIdx): ObjType="QD3DMESHBUILDER"
  CASE Q_D3DFRAME
    '            IF D3DFrameIdx>0 THEN EXIT SUB
    INC D3DFrameIdx: ObjIdx=D3DFrameIdx
    ObjName="D3DFrame"+STR$(ObjIdx): ObjType="QD3DFRAME"
  CASE Q_D3DLIGHT
    '            IF D3DLightIdx>0 THEN EXIT SUB
    INC D3DLightIdx: ObjIdx=D3DLightIdx
    ObjName="D3DLight"+STR$(ObjIdx): ObjType="QD3DLIGHT"
  CASE Q_D3DTEXTURE
    '            IF TextureIdx>0 THEN EXIT SUB
    INC TextureIdx: ObjIdx=TextureIdx
    ObjName="D3DTexture"+STR$(ObjIdx): ObjType="QD3DTEXTURE"
  CASE Q_D3DVECTOR
    '            IF VectorIdx>0 THEN EXIT SUB
    INC VectorIdx: ObjIdx=VectorIdx
    ObjName="D3DVector"+STR$(ObjIdx): ObjType="QD3DVECTOR"
  CASE Q_D3DWRAP
    '            IF D3DWrapIdx>0 THEN EXIT SUB
    INC D3DWrapIdx: ObjIdx=D3DWrapIdx
    ObjName="D3DWrap"+STR$(ObjIdx): ObjType="QD3DWRAP"
  CASE ELSE
    EXIT SUB
  END SELECT

  dNonVis(NonVIndex).Parent=NonVisPanel
  dNonVis(NonVIndex).Left=NonVisCount*32 + 5                      ' Position the button
  dNonVis(NonVIndex).Top=16
  dNonVis(NonVIndex).Width=30
  dNonVis(NonVIndex).Height=30
  dNonVis(NonVIndex).Hint=ObjName                                 ' Current component name
  dNonVis(NonVIndex).ShowHint=True
  dNonVis(NonVIndex).BMP=NonVisBMP.BMP                            ' Copy the bitmap image
  CurrentObject=ObjectIndex

  tstr=STR$(NewObjectID)+"|"+ObjType+"|"+STR$(dNonVis(NonVIndex).Handle)+"|"+ObjName+"|"+ObjName+"|0~"
  AddedObjectList(CurrentObject)=tstr+GetDefaultProperties(NewObjectID)

  SelectionCombo.AddItems ObjName+" ["+ObjType+"]"
  SelectionCombo.ItemIndex=CurrentObject
  UpdatePropGrid(CurrentObject)                                   ' Update String grid
  INC ObjectIndex: INC NonVIndex: INC NonVisCount
END SUB

' Checks that parent is a valid type
'*****************************************
FUNCTION IsParentValid(hWnd AS long) AS integer
  DEFINT i
  DEFSTR tstr

  FOR i=0 TO ObjectIndex-1
    tstr=AddedObjectList(i)
    IF hWnd=VAL(FIELD$(tstr,"|",3)) THEN
      tstr=FIELD$(tstr,"|",2)                                 ' Object type?
      SELECT CASE tstr                                        ' Is parent type?
      CASE "QFORM","QPANEL","QTABCONTROL","QGROUPBOX","QSCROLLBOX"
        Result=True
      CASE ELSE
        Result=False
      END SELECT
      EXIT FOR
    END IF
  NEXT i
END FUNCTION

'!*****************************************
SUB AddNewObject (parenthWnd  AS integer) ' hWnd is parent handle ,ObjName as string
  call  AddClrString ("3336:AddNewObject parent hWnd="+str$(parenthWnd), subclr, LogEdit)
  call  AddClrString ("3339:NewObjectID="+str$(NewObjectID), clb, LogEdit)


  inc ObjectCount
  call  AddClrString ("2074:ObjectCount="+str$(ObjectCount), clred, LogEdit)
  ObjectIndex=ObjectCount-1
  call  AddClrString ("2076:ObjectIndex="+str$(ObjectIndex), clred, LogEdit)

  IF ObjectCount>MAX_OBJECTS THEN ' ObjectIndex уже новый после addnewform
    MessageBox("3342:Maximum components ("+STR$(MAX_OBJECTS)+") has been reached","RapidFRM "+VER,&H30)
    NewObjectID=-1
    EXIT SUB
  END IF

  IF NewObjectID < NON_VISIBLE THEN
    ObjVisible(ObjectIndex)=1
  end if

  ObjParentIdx(ObjectIndex)=HandleToIndex(parenthWnd)


  HideCarets
  call  AddClrString ("------->>> 3395:NewObjectID="+str$(NewObjectID), clm, LogEdit)

  SELECT CASE NewObjectID

    '!!CASE -57: AddQMenuItem(parenthWnd AS long)
    'reDim BoxEdit(EdIndex+1) AS QPANEL
    'SetAddedObjProp(parenthWnd AS long,BoxEdit(EdIndex), "QEDIT", @EdIndex, 100, 30, clr, 1,"")


    '!!CASE -56: AddQMainMenu(parenthWnd AS long)
    'reDim BoxEdit(EdIndex+1) AS QPANEL
    'SetAddedObjProp(parenthWnd AS long,BoxEdit(EdIndex), "QEDIT", @EdIndex, 100, 30, clr, 1,"")



  CASE 1: ' AddQEDIT(parenthWnd)
    'reDim dPan(PanCount) AS QPANEL
    'PanIndex=PanCount-1
    ' inc PanCount

    reDim BoxEdit(EdCount) AS QPANEL
    EdIndex=EdCount-1
    inc EdCount

    SetAddedObjProp(parenthWnd AS long,BoxEdit(EdIndex), "QEDIT", @EdIndex, 100, 30, clr, 1,"")

  CASE 2: 'AddQRICHEDIT(parenthWnd)
    call  AddClrString ("3414:AddQRICHEDIT", clred, LogEdit)
    reDim BoxRich(RichCount) AS QPANEL
    RichIndex=RichCount-1
    inc RichCount

    SetAddedObjProp(parenthWnd,BoxRich(RichIndex), "QRICHEDIT", @RichIndex, 100, 50,clo,0,"")

  CASE 3:  AddQLABEL(parenthWnd)
    'reDim BoxLabel(LabelIndex+1) AS QLabel
    'SetAddedObjProp(parenthWnd AS long,BoxLabel(LabelIndex), "QLABEL", @LabelIndex, 70, 25,clw,0,"")

  CASE 4: 'AddQBUTTON(parenthWnd)
    reDim boxBut(ButnCount) AS QPANEL
    ButnIndex=ButnCount-1
    inc ButnCount

    SetAddedObjProp(parenthWnd,boxBut(ButnIndex), "QBUTTON", @ButnIndex, 75, 25,clsilver,2,"")

  CASE 5: ' AddQCOOLBTN(parenthWnd)
    reDim BoxCool(CoolCount) AS QPANEL
    CoolIndex=CoolCount-1
    inc CoolCount

    SetAddedObjProp(parenthWnd,BoxCool(CoolIndex), "QCOOLBTN", @CoolIndex, 25, 25,clsilver,2,"")

  CASE 6:   AddQOVALBTN(parenthWnd)


  CASE 7:
    AddQCHECKBOX(parenthWnd)

  CASE 8: AddQRADIOBUTTON(parenthWnd)

  CASE 9: ' AddQPANEL(parenthWnd) !!!
    reDim dPan(PanCount) AS QPANEL

    PanIndex=PanCount-1
    inc PanCount

    call  AddClrString ("!!!!!! 2113:parenthWnd="+str$(parenthWnd), clred, LogEdit)
    SetAddedObjProp(parenthWnd,dPan(PanIndex), "QPanel", @PanIndex, 150, 100,clsilver,2,"")
    '                   1            2                3          4       5    6    7      8  9
    'Declare SUB SetAddedObjProp(parenthWnd AS long,Sender AS QPANEL, otype as string, oIdx as long, oWidth as long,
    'oHeight as long, color as long, border as long, ChildeInPanelType as string)
    'INC ObjectCount: INC PanIndex

  CASE 10:  AddQTABCONTROL(parenthWnd)

  CASE 11:  AddQCOMBOBOX(parenthWnd)

  CASE 12:  AddQLISTBOX(parenthWnd)

  CASE 13:  AddQGROUPBOX(parenthWnd)

  CASE 14:  AddQSCROLLBOX(parenthWnd)

  CASE 15: AddQSCROLLBAR(parenthWnd)

  CASE 16: AddQSTRINGGRID(parenthWnd)

  CASE 17: AddQLISTVIEW(parenthWnd)

  CASE 18:  AddQDIRTREE(parenthWnd)

  CASE 19:  AddQFILELISTBOX(parenthWnd)

  CASE 20: AddQTREEVIEW(parenthWnd)

  CASE 21: AddQOUTLINE(parenthWnd)

  CASE 22: AddQGAUGE(parenthWnd)

  CASE 23: AddQTRACKBAR(parenthWnd)

  CASE 24: AddQHEADER(parenthWnd)

  CASE 25: AddQSTATUSBAR(parenthWnd)

  CASE 26:  AddQCANVAS(parenthWnd)


  CASE 27:  AddQIMAGE(parenthWnd)
    'reDim panImage(ImageIndex+1) AS QPANEL
    'SetAddedObjProp(parenthWnd AS long,panImage(ImageIndex), "QIMAGE", @ImageIndex, 150, 100,clw,1,"")



  CASE 28:  'AddQOLECONTAINER(parenthWnd)

    reDim oleContainer(OLEContIndex+1) AS QPANEL
    SetAddedObjProp(parenthWnd,oleContainer(OLEContIndex), "QOLECONTAINER", @OLEContIndex, 150, 100,clw,1,"")


  CASE 29: ' AddQSPLITTER(parenthWnd)

    reDim panSplit(SplitIndex+1) AS QPANEL

    SetAddedObjProp(parenthWnd,panSplit(SplitIndex), "QSPLITTER", @SplitIndex, 5, Forms(FormIndex).ClientHeight,clgray,2,"")


  CASE 30 TO 55: AddNonVisible(parenthWnd)
    '==========
    'erem
  END SELECT

  'call  AddClrString ("=== 4761:end add NewObjectID="+str$(NewObjectID), 0, LogEdit)
  NewObjectID=-1

  'PropertyValueUpdate
END SUB




'*****************************************
SUB AddNewObject_Old
  call  AddClrString ("5010:AddNewObject="+str$(AddNewObject), clg, LogEdit)
  DEFLNG hWnd

  IF ObjectIndex>MAX_OBJECTS THEN
    MessageBox("3999:Maximum components ("+STR$(MAX_OBJECTS)+") has been reached","RapidFRM "+VER,&H30)
    NewObjectID=-1
    EXIT SUB
  END IF

  IF NewObjectID < NON_VISIBLE THEN
    call  AddClrString ("4716:NewObjectID="+str$(NewObjectID), clred, LogEdit)
    hWnd=WindowFromPoint(Screen.MouseX,Screen.MouseY)
    call  AddClrString ("5104:hWnd="+str$(hWnd), clred, LogEdit)

    IF IsParentValid(hWnd)=False THEN
      hWnd=GetParent(hWnd)
      IF IsParentValid(hWnd)=False THEN
        MessageBox("4008: ERROR: Non-valid parent?","RapidFRM "+VER,&H30)
        NewObjectID=-1
        EXIT SUB
      END IF
    END IF
  END IF
  HideCarets
  call  AddClrString ("---5011:NewObjectID="+str$(NewObjectID), clred, LogEdit)

  SELECT CASE NewObjectID
  CASE 1: AddQEDIT(hWnd)
  CASE 2: AddQRICHEDIT(hWnd)
  CASE 3: AddQLABEL(hWnd)
  CASE 4: AddQBUTTON(hWnd)
  CASE 5: AddQCOOLBTN(hWnd)
  CASE 6: AddQOVALBTN(hWnd)
  CASE 7: AddQCHECKBOX(hWnd)
  CASE 8: AddQRADIOBUTTON(hWnd)
  CASE 9: AddQPANEL(hWnd)
  CASE 10: AddQTABCONTROL(hWnd)
  CASE 11: AddQCOMBOBOX(hWnd)
  CASE 12: AddQLISTBOX(hWnd)
  CASE 13: AddQGROUPBOX(hWnd)
  CASE 14: AddQSCROLLBOX(hWnd)
  CASE 15: AddQSCROLLBAR(hWnd)
  CASE 16: AddQSTRINGGRID(hWnd)
  CASE 17: AddQLISTVIEW(hWnd)
  CASE 18: AddQDIRTREE(hWnd)
  CASE 19: AddQFILELISTBOX(hWnd)
  CASE 20: AddQTREEVIEW(hWnd)
  CASE 21: AddQOUTLINE(hWnd)
  CASE 22: AddQGAUGE(hWnd)
  CASE 23: AddQTRACKBAR(hWnd)
  CASE 24: AddQHEADER(hWnd)
  CASE 25: AddQSTATUSBAR(hWnd)
  CASE 26: AddQCANVAS(hWnd)
  CASE 27: AddQIMAGE(hWnd)
  CASE 28: AddQOLECONTAINER(hWnd)
  CASE 29: AddQSPLITTER(hWnd)
  CASE 30 TO 55: AddNonVisible(hWnd)
  END SELECT
  NewObjectID=-1
  'call  AddClrString ("4761:NewObjectID="+str$(NewObjectID), clred, LogEdit)
END SUB

'----------------- Template insertion for QMAINMENU/QPOPUPMENU --------------------
' Entry point MenuEditor()
'
' Update the temp global string with original menu code
' plus the newly selected code. Update screen text.
'*****************************************
SUB LoadMenu(which AS integer, index AS integer) '!!!! <<<<<<<<<<<<<<< необновленные процедуры

  DEFINT i
  DEFSTR tstr, token, ThisParent=""

  MenuText.Clear
  IF which=MAINMENU THEN
    MenuUpdateStr=LTRIM$(MainMenuList)                          ' Load current QMAINMENU code
    token="#7"                                                  ' Marker in help/reference file
    ThisParent=LTRIM$(RTRIM$(cbMMenu.Item(cbMMenu.ItemIndex)))  ' A parent selected?
  ELSE
    MenuUpdateStr=LTRIM$(PopMenuList)                           ' Load current QPOPUPMENU code
    token="#8"                                                  ' Marker in help/reference file
  END IF
  HelpRef.Position=0
  FOR i=1 TO HelpRef.LineCount
    tstr=HelpRef.ReadLine
    IF FIELD$(tstr," ",1)=token THEN EXIT FOR                   ' Position within the mem stream
  NEXT i

  token=STR$(index)                                               ' A unique index
  tstr="The following code will be added to your project:"
  MenuText.AddStrings "", tstr, ""
  FOR i=i+1 TO HelpRef.LineCount                                  ' Fill the menu editbox
    tstr=HelpRef.ReadLine-CHR$(13)-CHR$(10)
    IF LEFT$(tstr,1)="#" THEN EXIT FOR                          ' End of section text
    IF INSTR(tstr,"##")>0 THEN tstr=REPLACESUBSTR$(tstr,"##",token)     ' Insert unique ID
    IF INSTR(UCASE$(tstr),"PARENT")>0 THEN
      IF ThisParent<>"" THEN tstr="    Parent = "+ThisParent
    END IF
    IF NOT ((chkMenu.Checked=False) AND (LEFT$(tstr,1)="'")) THEN
      MenuUpdateStr=MenuUpdateStr+LTRIM$(tstr)+"~"            ' Update the new string
      IF INSTR(UCASE$(tstr),"CAPTION")>0 THEN
        tstr=RTRIM$(FIELD$(tstr,"=",1))+" = "+QU+LTRIM$(FIELD$(tstr,"=",2))+QU
      END IF
      MenuText.AddStrings tstr                                ' Update the displayed text
    END IF
  NEXT i
  MenuUpdateStr=LEFT$(MenuUpdateStr,LEN(MenuUpdateStr)-1)+"@"     ' Terminate string with "@"
END SUB

' User selected option
'*****************************************
SUB OptionChange
  SELECT CASE btnUpdate.Tag
  CASE MAINMENU: LoadMenu(MAINMENU,MainMenuIndex)             ' Place text in display window
  CASE POPMENU: LoadMenu(POPMENU,PopUpIndex)                  ' ditto
  END SELECT
END SUB

' Update display of QMAINMENU
'*****************************************
SUB ParentChange
  IF btnUpdate.Tag=MAINMENU THEN                                  ' Which menu adding?
    btnUpdate.Enabled=True                                      ' Enable the "save" button
    LoadMenu(MAINMENU,MainMenuIndex)                            ' Place text in display window
  END IF
END SUB

' Display a QMAINMENU code template
'*****************************************
SUB AddMainMenu
  btnUpdate.Tag=MAINMENU                                          ' Which menu adding?
  btnUpdate.Enabled=True                                          ' Enable the "save" button
  LoadMenu(MAINMENU,MainMenuIndex)                                ' Place text in display window
END SUB

' Display a QPOPUPMENU code template
'*****************************************
SUB AddPopupMenu
  btnUpdate.Tag=POPMENU                                           ' Which menu adding?
  btnUpdate.Enabled=True                                          ' Enable the "save" button
  LoadMenu(POPMENU,PopUpIndex)                                    ' Place text in display window
END SUB

'*****************************************
SUB UpdateFwdDeclares '!!!! <<<<<<<<<<<<<<< необновленные процедуры

  DEFSTR tstr, token
  DEFINT i

  SELECT CASE btnUpdate.Tag
  CASE MAINMENU: tstr=MenuUpdateStr-MainMenuList
  CASE POPMENU: tstr=MenuUpdateStr-PopMenuList
  END SELECT
  FOR i=1 TO TALLY(tstr,"~")
    token=FIELD$(tstr,"~",i)
    IF RTRIM$(FIELD$(token,"=",1))="OnClick" THEN
      FwdDeclares=FwdDeclares+"SUB "+LTRIM$(FIELD$(token,"=",2))+"~"
    END IF
  NEXT i
END SUB

' Insert selected code into project
'*****************************************
SUB UpdateProjectMenu '!!!! <<<<<<<<<<<<<<< необновленные процедуры

  DEFSTR tstr

  UpdateFwdDeclares
  SELECT CASE btnUpdate.Tag
  CASE MAINMENU
    MainMenuList=MenuUpdateStr                              ' Update the global string
    INC MainMenuIndex                                       ' Update the unique index
    tstr=RTRIM$(cbMMenu.Item(cbMMenu.ItemIndex))            ' Attached to a project form?
    IF tstr<>"" THEN
      cbMMenu.DelItems(cbMMenu.ItemIndex)                 ' Remove form from combo
    END IF
  CASE POPMENU
    PopMenuList=MenuUpdateStr                               ' Update the global string
    INC PopUpIndex                                          ' Update the unique index
  END SELECT
  btnUpdate.Tag=0                                                 ' Clear "saved" menu option
  btnUpdate.Enabled=False
  MenuText.Clear
END SUB

' "Menus" TAB selected
'*****************************************
SUB MenuEditor '!!!! <<<<<<<<<<<<<<< необновленные процедуры

  DEFINT i, j
  DEFSTR tstr, token, frmNames=" "

  cbMMenu.Clear                                                   ' Start with an empty combobox
  FOR i=0 TO ObjectIndex-1
    tstr=FIELD$(AddedObjectList(i),"~",1)
    IF FIELD$(tstr,"|",2)="QFORM" THEN
      frmNames=frmNames+FIELD$(tstr,"|",5)+"~"
    END IF
  NEXT i
  frmNames=LTRIM$(frmNames)

  MainMenuIndex=TALLY(MainMenuList,"@")
  IF MainMenuIndex>0 THEN
    FOR i=1 TO MainMenuIndex                                    ' From QMAINMENUs list
      tstr=LTRIM$(FIELD$(MainMenuList,"@",i))+"~"
      IF INSTR(UCASE$(tstr),"PARENT")>0 THEN                  ' Has a parent form?
        FOR j=1 TO TALLY(tstr,"~")
          token=FIELD$(tstr,"~",j)
          IF INSTR(UCASE$(token),"PARENT")>0 THEN
            token=LTRIM$(FIELD$(token,"=",2))+"~"
            frmNames=frmNames-token                     ' Add form name to list
          END IF
        NEXT j
      END IF
    NEXT i
  END IF

  cbMMenu.AddItems(" ")                                           ' Add blank parent entry!
  FOR i=1 TO TALLY(frmNames,"~")
    tstr=FIELD$(frmNames,"~",i)
    cbMMenu.AddItems(tstr)                                      ' Add form name to combobox
  NEXT i
  cbMMenu.Text="<Select a parent form>"                           ' Display default text

  INC MainMenuIndex                                               ' A unique ID?
  PopUpIndex=TALLY(PopMenuList,"@")+1                             ' ditto

  MenuPanel.Visible=True
  MenuPanel.Repaint
  MenuText.Clear
  btnUpdate.Enabled=False                                         ' Disable the save button
END SUB

'
'--------------------- Display loaded project code ----------------------------
' Parse the input stream, then populate the Form Designer screen with user info
' Entry point ParseInputStream()
'------------------------------------------------------------------------------
' Update the AddedObjectList string with object name
'*****************************************
SUB UpdateObjList(objectName AS string) '!!!! <<<<<<<<<<<<<<< необновленные процедуры

  call  AddClrString ("5456:UpdateObjList="+str$(UpdateObjList), clg, LogEdit)
  DEFINT i, cnt
  DEFSTR tstr, tok1, tok2

  tstr=AddedObjectList(CurrentObject)                                  ' This component property strings
  tok1=FIELD$(tstr,"~",1)                                         ' Component identifier string
  tstr=tstr-tok1

  cnt=TALLY(tok1,"|")+1                                           ' Number of fields
  tok2=""
  FOR i=1 TO 4
    tok2=tok2+FIELD$(tok1,"|",i)+"|"                            ' Build first four fields
  NEXT i
  tok2=tok2+objectName                                            ' Add new fifth field
  FOR i=i+1 TO cnt
    tok2=tok2+"|"+FIELD$(tok1,"|",i)                            ' Add remainder of fields
  NEXT i
  tstr=tok2+tstr                                                  ' Replace new identifier string
  AddedObjectList(CurrentObject)=tstr                                  ' Put back into global string array
END SUB

'*****************************************
SUB UpdateObjCombo(newObject AS string)
  call  AddClrString ("5479:UpdateObjCombo="+str$(UpdateObjCombo), clg, LogEdit)
  SelectionCombo.DelItems(ObjectIndex-1)                          ' Remove the default obj name
  SelectionCombo.AddItems newObject                               ' Add the real object name
END SUB

'*****************************************
SUB UpdateNewProperty(srcString AS string) '!!!! <<<<<<<<<<<<<<< необновленные процедуры

  DEFINT i, offset
  DEFSTR ObjString, tstr, token

  ObjString=AddedObjectList(CurrentObject)                             ' All properties/events this object
  offset=4                                                        ' Default -> properties 4th field
  token=UCASE$(RTRIM$(FIELD$(srcString,"=",1)))                   ' Update this property or event
  IF (LEFT$(token,2)="ON") OR (token="WNDPROC") THEN offset=2     ' An Event? Update 2nd field
  FOR i=1 TO TALLY(ObjString,"~")
    tstr=FIELD$(ObjString,"~",i)
    IF UCASE$(FIELD$(tstr,"|",1))=token THEN                    ' Found the property
      token=LTRIM$(FIELD$(srcString,"=",2))                   ' New value
      PropertyFieldUpdate(FIELD$(tstr,"|",1),token) ' ,offset   ' Update global AddedObjectList()
      EXIT FOR
    END IF
  NEXT i
END SUB

' Start=second line of CREATE .. END CREATE string block
' NB can be other objects mixed with THIS objects properties!
'*****************************************
SUB UpdateObjGrid(Start AS integer, blkString AS string) '!!!! <<<<<<<<<<<<<<< необновленные процедуры

  call  AddClrString ("5507:UpdateObjGrid="+str$(UpdateObjGrid), clg, LogEdit)
  DEFINT i, cnt, lev
  DEFSTR tstr, token

  lev=1                                                           ' Want all props THIS lev (object)
  cnt=TALLY(blkString,"~")
  FOR i=Start TO cnt
    tstr=FIELD$(blkString,"~",i)                                ' For each line of this new object
    token=UCASE$(FIELD$(tstr," ",1))
    SELECT CASE token
    CASE "CREATE": INC lev                                  ' A different object?
    CASE "END": DEC lev: IF lev=0 THEN EXIT FOR             ' End of the properties this object
    CASE ELSE
      IF (lev=1) AND (INSTR(tstr,"=")>0) THEN             ' "Property = value"?
        UpdateNewProperty(tstr)
      END  IF
    END SELECT
  NEXT i
  UpdatePropGrid(CurrentObject)
END SUB

'*****************************************
FUNCTION ExtractObjectID(objType AS string) AS integer '!!!! <<<<<<<<<<<<<<< необновленные процедуры

  call  AddClrString ("5530:ExtractObjectID=", clg, LogEdit)
  DEFINT i
  DEFSTR tstr

  IF LEFT$(objType,5)="QFORM" THEN                                ' Includes QformEx
    Result=0                                                    ' ObjectID=0
  ELSE
    FOR i=1 TO MAX_TOOLBTNS '!!! ?????????????
      tstr=UCASE$(FIELD$(ToolbarHint,"~",i))
      IF objType=tstr THEN EXIT FOR
    NEXT i
    Result=i
  END IF
END FUNCTION

'*****************************************
' Update defaults for this form, then redraw it
SUB RepaintNewForm(frmString AS string)  '!!!! <<<<<<<<<<<<<<< необновленные процедуры

  DEFINT i, lev
  DEFINT left, top, width, height, defWidth, defHeight
  DEFSTR tstr, token, cap

  left=0: top=0: width=0: height=0                                ' Preset defaults
  defWidth=Forms(FormIndex).Width: defHeight=Forms(FormIndex).Height
  cap="Form"+STR$(FrmIndex-1)                                     ' A default caption
  lev=1
  FOR i=2 TO TALLY(frmString,"~")                                 ' Start after the create form line
    tstr=LTRIM$(FIELD$(frmString,"~",i))
    IF UCASE$(LEFT$(tstr,7))="CREATE " THEN
      INC lev
    ELSEIF UCASE$(LEFT$(tstr,7))="END CRE" THEN
      DEC lev
      IF lev=0 THEN EXIT FOR                                  ' End of this Form
    ELSEIF (lev=1) AND (INSTR(tstr,"=")>0) THEN
      token=UCASE$(RTRIM$(FIELD$(tstr,"=",1)))
      SELECT CASE token
      CASE "LEFT": left=VAL(LTRIM$(FIELD$(tstr,"=",2)))
      CASE "TOP": top=VAL(LTRIM$(FIELD$(tstr,"=",2)))
      CASE "WIDTH": width=VAL(LTRIM$(FIELD$(tstr,"=",2)))
      CASE "HEIGHT": height=VAL(LTRIM$(FIELD$(tstr,"=",2)))
      CASE "CAPTION": cap=LTRIM$(FIELD$(tstr,"=",2))
      END SELECT
    END IF
  NEXT i
  ' FIXME: Check for some sanity values, and fudge if necessary - should log this!
  IF left<0 THEN left=0: IF top<0 THEN top=0
  IF width<=0 THEN width=defWidth: IF height<=0 THEN height=defHeight

  SetWindowPos(Forms(FormIndex).Handle, 0, left, top, width, height, SW_FLAGS)
  SetWindowText(Forms(FormIndex).Handle,cap)
END SUB

' Get SCREEN properties of object into a rect, then refresh it visually (NOT forms)
' Added MAJOR fudge v1.45 for QOvalBtn
'*****************************************
SUB RepaintNewObject(Start AS integer, frmString AS string)  '!!!! <<<<<<<<<<<<<<< необновленные процедуры

  DEFINT i, lev, OvalIdx=0
  DEFINT width, height
  DEFLNG hWnd
  DEFSTR tstr, token, cap
  DIM tRect AS QRECT
  DIM tPoint AS PointAPI

  tstr=AddedObjectList(CurrentObject)                                  ' Default properties this new object
  'call  AddClrString ("4661:tstr="+str$(tstr), clred, LogEdit)
  token=FIELD$(tstr,"~",1)                                        ' Object header info
  hWnd=VAL(FIELD$(token,"|",3))                                   ' Get its handle

  IF VAL(FIELD$(token,"|",1))=Q_OVALBTN THEN                      ' QOvalBtn?
    OvalIdx=VAL(FIELD$(token,"|",7))                            ' NEED this extra info
  END IF
  FOR i=2 TO TALLY(tstr,"~")                                      ' Default width & height of this object
    token=UCASE$(FIELD$(tstr,"~",i))
    SELECT CASE FIELD$(token,"|",1)
    CASE "WIDTH": Width=VAL(FIELD$(token,"|",4) )            ' Default if error reading code parms
    CASE "HEIGHT": Height=VAL(FIELD$(token,"|",4) )          ' ditto
    END SELECT
  NEXT i
  tPoint.x=0: tPoint.y=0: lev=1: cap=""                           ' Start for this object

  ' Update with object data
  FOR i=Start TO TALLY(frmString,"~")
    tstr=LTRIM$(FIELD$(frmString,"~",i))
    IF UCASE$(LEFT$(tstr,7))="CREATE " THEN
      INC lev
    ELSEIF UCASE$(LEFT$(tstr,7))="END CRE" THEN
      DEC lev
      IF lev=0 THEN EXIT FOR
    ELSEIF (lev=1) AND (INSTR(tstr,"=")>0) THEN
      token=UCASE$(RTRIM$(FIELD$(tstr,"=",1)))
      SELECT CASE token
      CASE "LEFT": tPoint.x=VAL(LTRIM$(FIELD$(tstr,"=",2)))
      CASE "TOP": tPoint.y=VAL(LTRIM$(FIELD$(tstr,"=",2)))
      CASE "WIDTH": width=VAL(LTRIM$(FIELD$(tstr,"=",2)))
      CASE "HEIGHT": height=VAL(LTRIM$(FIELD$(tstr,"=",2)))
      CASE "CAPTION": cap=LTRIM$(FIELD$(tstr,"=",2))
      END SELECT
    END IF
  NEXT i

  ' Just in case something goes wrong
  IF tPoint.x<0 THEN tPoint.x=0: IF tPoint.y<0 THEN tPoint.y=0
  ' MS Themes allow different Active TitleBar heights which alters vertical positioning (inexplicably!)
  ' of objects.  Check if this object's parent is a form and adjust vertical position accordingly.
  IF GetParent(hWnd)=Forms(FormIndex).Handle THEN               ' Object's parent a form?
    tPoint.y = tPoint.y+ThemeOffsetY                            ' Possible adjustment
  END IF

  IF OvalIdx>0 THEN                                               ' Special case QOvalBtn
    OvalRepaint(OvalIdx,tPoint.x,tPoint.y,width,height,cap)
  ELSE
    ClientToScreen(hWnd,tPoint)                                 ' Get object in screen co-ords..
    tRect.Left=tPoint.x                                         ' ..and fill tRect
    tRect.Top=tPoint.y
    tRect.Right=tRect.Left+width
    tRect.Bottom=tRect.Top+height
    RefreshObject(hWnd,tRect)                                   ' Repaint the object
    IF cap<>"" THEN
      SetWindowText(hWnd,cap)                                 ' Update it's caption
    END IF
  END IF
END SUB

' Need to set the cursor in a "free" area of the parent object
' NB there may be other child objects in this parent!
'*****************************************
FUNCTION SetCursorInParent(hWnd AS long, objType AS string) AS integer '!!!! <<<<<<<<<<<<<<< необновленные процедуры

  DEFINT px, py, y
  DIM pRect AS QRECT

  call  AddClrString ("5657:objType="+(objType), clo, LogEdit)

  Result=True
  GetWindowRect(hWnd,pRect)                                       ' Current object rectangle
  SELECT CASE objType                                             '
  CASE "QFORM"                                                '|
    px=pRect.Left+4: py=pRect.Top+23                        '|
  CASE "QSCROLLBOX"                                           '| Set "Client area" start posn..
    px=pRect.Left+2: py=pRect.Top+2                         '| ..of this parent object
  CASE "QPANEL","QGROUPBOX","QTABCONTROL"                     '|
    px=pRect.Left: py=pRect.Top                             '|
    call  AddClrString ("5671:px="+str$(px), clred, LogEdit)
  CASE ELSE                                                   ' Non-parent object?
    px=pRect.Left: py=pRect.Top
    call  AddClrString ("5673:px="+str$(px), clred, LogEdit)
    SetCursorPos(px,py)                                     ' Left-Top of this object
    EXIT FUNCTION
  END SELECT
  FOR px=px TO pRect.Right STEP 2                                 ' Scan across the parent window..
    FOR y=py TO pRect.Bottom STEP 2                             ' ..for "free" area

      wfp&=WindowFromPoint(px,y)
      IF WindowFromPoint(px,y)=hWnd THEN
        SetCursorPos(px,y)                                  ' Inside this object rectangle
        EXIT FUNCTION
      END IF
    Next y
  NEXT px
  call  AddClrString ("5681:WindowFromPoint("+str$(px)+")="+str$(wfp&), cla, LogEdit)

  Result=False
END FUNCTION

' Insert object onto the current parent. This fn is recursive
' as it may be a single object or a parent object with siblings
'*****************************************
FUNCTION InsertObjBlock(Start AS integer, frmString AS string) AS integer
  call  AddClrString ("5510:InsertObjBlock=", clg, LogEdit)
  DEFSTR tstr, objType
  DEFLNG hWnd
  DEFINT i, cnt

  tstr=FIELD$(frmString,"~",Start)
  call  AddClrString ("5698:Start="+str$(Start), cldg, LogEdit)
  call  AddClrString ("5700:tstr="+(tstr), cldr, LogEdit)
  objType=UCASE$(FIELD$(tstr," ",4) )                              ' Object type to add
  call  AddClrString ("5700:objType="+(objType), cldr, LogEdit)
  NewObjectID=ExtractObjectID(objType)                            ' Set the global ID B4 adding it
  IF objType="QFORM" THEN
    call  AddClrString ("12319:objType="+str$(objType), clred, LogEdit)
    AddNewForm                                                  ' Add a "default" QForm
    RepaintNewForm(frmString)                                   ' Re-size & re-position it
    call  AddClrString ("5706:frmString="+left$(frmString,2048), cldr, LogEdit)
  ELSE
    AddNewObject (0)                                               ' Add a "default" object to the parent
    RepaintNewObject(Start+1,frmString)                         ' Re-size & re-position it
  END IF
  ScanTimer.Enabled=False                                              ' MUST do this after adding a component
  'call  AddClrString ("5175:ScanTimer.Enabled="+str$(ScanTimer.Enabled), clred, LogEdit)

  tstr=FIELD$(tstr," ",2)                                         ' Object name
  call  AddClrString ("5714:Object name tstr="+(tstr), clred, LogEdit)
  UpdateObjList(tstr)                                             ' Update AddedObjectList string
  UpdateObjCombo(tstr+" ["+objType+"]")                           ' Replace default with actual name
  UpdateObjGrid(Start+1,frmString)                                      ' Update PropertyGrid info

  tstr=AddedObjectList(ObjectIndex-1)                                  ' Get new object properties
  'call  AddClrString ("5724:tstr="+(tstr), cldr, LogEdit)
  hWnd=VAL(FIELD$(tstr,"|",3))                                    ' Get new object handle

  cnt=TALLY(frmString,"~")                                        ' Parse for any child objects
  FOR i=Start+1 TO cnt
    tstr=LTRIM$(FIELD$(frmString,"~",i))
    'call  AddClrString ("5730:tstr="+(tstr), clo, LogEdit)
    SELECT CASE UCASE$(LEFT$(tstr,6))
    CASE "END CR"                                           ' Test for exit condition FIRST!
      Result=i                                            ' MUST return THIS field number!
      call  AddClrString ("5734:i="+str$(i), clred, LogEdit)
      EXIT FUNCTION                                       ' Oddity: Cannot do <EXIT FOR> here!
    CASE "CREATE"
      IF SetCursorInParent(hWnd,objType) THEN             ' Set cursor inside the current object
        'IF 1=1 THEN             ' Set cursor inside the current object
        i=InsertObjBlock(i,frmString)                   '!!! RECURSIVELY call THIS function
        IF i = -1 THEN                                  ' Failed?
          Result = -1                                 ' Abort the chain
          EXIT FUNCTION
        END IF
      ELSE
        tstr="Internal eror!"+CRLF
        tstr=tstr+"SetCursorInParent() failed for parent of "+objType
        call  AddClrString ("5700:tstr============"+(tstr), cldp, LogEdit)
        MessageBox(tstr,"Unknown parse error",&h30)
        Result = -1                                     ' Failed? Abort the chain
        EXIT FUNCTION
      END IF
    END SELECT
  NEXT i
  ScanTimer.Enabled=True                                              ' MUST do this after adding a component
  'call  AddClrString ("5209:ScanTimer.Enabled="+str$(ScanTimer.Enabled), clred, LogEdit)

END FUNCTION

' frmString is the CREATE ... END CREATE of a FORM with included components
' Oddity: Need this "stub" function to call the recursive function InsertObjBlock()
' Stack must get corrupted and returning FROM THIS stub "tidies" it all up(????)
' InsertObjBlock() is a function, but not interested in the Result returned!

'*****************************************
SUB InsertThisForm(frmString AS string)
  InsertObjBlock(1,frmString)                                     ' Start from first field - the form
END SUB

'*****************************************
' Get all event sub names from current AddedObjectList() into FwdDeclarations string
SUB BuildFwdDeclarations
  DEFINT i, j
  DEFSTR tstr, tok1, tok2

  FwdDeclares=" "
  FOR i=0 TO MAX_OBJECTS                                          ' Add forward declarations..
    tstr=AddedObjectList(i)                                          ' ..for any object events found
    IF tstr="" THEN EXIT FOR                                    ' End of object list so exit
    FOR j=1 TO TALLY(tstr,"~")
      tok1=FIELD$(tstr,"~",j)                                 ' Each property/event line
      tok2=UCASE$(FIELD$(tok1,"|",1))
      IF (LEFT$(tok2,2)="ON") OR (tok2="WNDPROC") THEN        ' An event?
        tok2=FIELD$(tok1,"|",2)                             ' Get sub name if exist
        IF (tok2<>"") AND (INSTR(FwdDeclares,tok2)=0) THEN  ' Does NOT exist already!
          tok2=tok2+FIELD$(tok1,"|",3)                    ' Get parameters
          FwdDeclares=FwdDeclares+"SUB "+tok2+"~"         ' Save this for adding a template sub
        END IF
      END IF
    NEXT j
  NEXT i
  FwdDeclares=LTRIM$(FwdDeclares)
END SUB

'*****************************************
'FIXME: Code here ok but incomplete (non-default properties not updated)
SUB ParseNonVisible
  DEFINT i, j, cnt, found
  DEFSTR tstr, objType, resString=" "

  cnt=TALLY(KnownsList,"@")
  FOR i=1 TO cnt
    found=False
    tstr=TRIM$(FIELD$(KnownsList,"@",i))
    tstr=FIELD$(tstr,"~",1)
    objType=UCASE$(TRIM$(FIELD$(tstr," ",4) ))
    FOR j=1 TO MAX_TOOLBTNS
      IF objType=UCASE$(FIELD$(ToolBarHint,"~",j)) THEN
        IF j >= NON_VISIBLE THEN
          NewObjectID=j
          AddNewObject(0)
          'FIXME: Need to update properties of each new object here!!!!!!
          found=True
        END IF
        EXIT FOR
      END IF
    NEXT j
    IF found=False THEN
      tstr=TRIM$(FIELD$(KnownsList,"@",i))
      resString=resString+tstr+"@"
    END IF
  NEXT i
  KnownsList=LTRIM$(resString)                                    ' Anything not accounted for
END SUB

'*****************************************
SUB ShowProject
  call  AddClrString ("5821:ShowProject=", clg, LogEdit)
  DEFINT i, cnt
  DEFSTR tstr, exForms

  DelayTimer.Enabled=False                                        ' Start-up delay timer disabled
  ScanTimer.Enabled=False                                              ' Just in case!
  'call  AddClrString ("5286:ScanTimer.Enabled="+str$(ScanTimer.Enabled), clred, LogEdit)
  ExistDeclares=" ": exForms=" "

  cnt=TALLY(FormsList,"@")
  IF cnt>MAX_FORMS THEN
    tstr="The maximum number of forms has been exceeded!"+CRLF
    tstr=tstr+"Only the FIRST "+STR$(MAX_FORMS)+" forms can be edited!"
    MessageBox(tstr,"RapidFRM "+VER,&h30)
  END IF
  IF cnt=0 THEN                                                   ' Didn't find any forms?
    tstr="NO forms found in input "
    IF ProjectMode=INPUT_FILE THEN
      tstr=tstr+"file!"+CRLF+CRLF
    ELSE
      tstr=tstr+"clipboard data!"+CRLF+CRLF
    END IF
    tstr=tstr+"Generating one 'Default' form."
    'MessageBox(tstr,"RapidFRM "+VER,&h30)
    'AddNewForm                                                  ' Add a "default" QForm
  ELSE
    i=1
    DO
      tstr=LTRIM$(FIELD$(FormsList,"@",i))
      IF i>MAX_FORMS THEN
        exForms=exForms+tstr+"@"                            ' List of excess forms
      ELSE
        InsertThisForm(tstr+"~")
      END IF
      INC i
    LOOP UNTIL i>cnt
    exForms=LTRIM$(exForms)
    UnKnownList=exForms+LTRIM$(UnKnownList)                     ' Anything > MAX_FORMS -> UnKnownList
  END IF
  ' FIXME: currently works but properties not updated!
  '    ParseNonVisible                                                 ' Add final objects in the KnownsList

  BuildFwdDeclarations                                            ' From the current Design Screen objects
  FOR i=1 TO TALLY(FwdDeclares,"~")
    tstr=FIELD$(FwdDeclares,"~",i)
    IF INSTR(tstr,"(")>0 THEN tstr=RTRIM$(FIELD$(tstr,"(",1))   ' Remove any parameters
    ExistDeclares=ExistDeclares+tstr+"~"                        ' Update global ExistDeclares
  NEXT i
  ExistDeclares=LTRIM$(ExistDeclares)
  FwdDeclares=" "                                                 ' Clear ready to add/update

  ScanTimer.Enabled=True                                               ' Ready to start editing
  'call  AddClrString ("5332:ScanTimer.Enabled="+str$(ScanTimer.Enabled), clred, LogEdit)
END SUB

'*****************************************
' No TABs, no comments, no quote chars and ensure single spaced word separaters
FUNCTION ReformatLine(inpStr AS string) AS string
  DEFSTR tstr, tok1, tok2, resString

  tstr=REPLACESUBSTR$(inpStr,CHR$(9)," ")                         ' Replace any TABs
  IF (UCASE$(LEFT$(tstr,4 ))="REM ") OR (LEFT$(tstr,1)="'") OR _
  (LTRIM$(tstr)="") THEN      ' Entire line a comment or blank?
  Result=""
  EXIT FUNCTION
END IF
IF INSTR(tstr,"'")>0 THEN                                       ' Remove any comments in line
  tstr=RTRIM$(FIELD$(tstr,"'",1))                             ' FIXME: Single ' inside double " string?
END IF
tstr=REPLACESUBSTR$(tstr,QU," ")                                ' Remove "quote chars" around strings
tstr=LTRIM$(RTRIM$(tstr))                                       ' Trim the line

resString=" "
IF INSTR(tstr,"=")>0 THEN
  tok1=RTRIM$(FIELD$(tstr,"=",1))+" = "
  tok2=LTRIM$(FIELD$(tstr,"=",2))
  resString=tok1+tok2
ELSE
  WHILE tstr<>""
    tok1=FIELD$(tstr," ",1)
    resString=resString+tok1+" "
    tstr=LTRIM$(RIGHT$(tstr,LEN(tstr)-LEN(tok1)))
  WEND
END IF
Result=LTRIM$(RTRIM$(resString))
END FUNCTION

'*****************************************
' Extract menus and "unknowns" from form strings
FUNCTION ExtractOther(StartIdx AS integer, inpString AS string) AS integer
  call  AddClrString ("5919:ExtractOther=", clg, LogEdit)
  DEFSTR tstr, token, ParentName, objString
  DEFINT i, cnt, lev

  ParentName=FIELD$(inpString," ",2)                              ' The current form's name
  call  AddClrString ("5924:ParentName="+(ParentName), clred, LogEdit)

  objString=FIELD$(inpString,"~",StartIdx)+"~"                    ' The "create" line of this object
  call  AddClrString ("5926:objString="+(objString), clred, LogEdit)

  IF UCASE$(FIELD$(objString," ",4))<>"QPOPUPMENU~" THEN
    tstr="Parent = "+ParentName+"~"                             ' MainMenus & unknowns only
    objString=objString+tstr
  END IF
  call  AddClrString ("5934:objString="+(objString), clrdb, LogEdit)

  lev=1: cnt=TALLY(inpString,"~")+1
  FOR i=StartIdx+1 TO cnt
    tstr=FIELD$(inpString,"~",i)
    token=UCASE$(FIELD$(tstr," ",1))
    IF token="CREATE" THEN
      INC lev
    ELSEIF token="END" THEN
      DEC lev
    END IF
    objString=objString+tstr+"~"
    IF lev=0 THEN EXIT FOR
  NEXT i

  objString=LEFT$(objString,LEN(objString)-1)                     ' Remove trailing "~"
  call  AddClrString ("5949:objString="+(objString), cldb, LogEdit)
  tstr=FIELD$(inpString,"~",StartIdx)                             ' First line "create"
  token=UCASE$(FIELD$(tstr," ",4))                                ' This object type
  SELECT CASE token                                               ' Add to the appropriate list
  CASE "QMAINMENU": MainMenuList=MainMenuList+objString+"@"
  CASE "QPOPUPMENU": PopMenuList=PopMenuList+objString+"@"
  CASE ELSE
    UnknownList=UnknownList+objString+"@"
  END SELECT
  call  AddClrString ("5954:MainMenuList="+str$(MainMenuList), clo, LogEdit)
  call  AddClrString ("5956:PopMenuList="+str$(PopMenuList), clo, LogEdit)
  call  AddClrString ("5959:UnknownList="+str$(UnknownList), clo, LogEdit)


  Result=i                                                        ' Line index of the "end create"
END FUNCTION

'*****************************************
' Parse form string storing in formslist, removing menus & unknowns
SUB ParseForm(inpString AS string)
  call  AddClrString ("5949:ParseForm=", clg, LogEdit)
  DEFINT i, cnt, objType
  DEFSTR tstr, token, frmString

  frmString=FIELD$(inpString,"~",1)+"~"
  call  AddClrString ("5949:frmString="+(frmString), clred, LogEdit) '!!! CREATE MainForm AS QFORM~
  'call  AddClrString ("5949:inpString="+(inpString), clred, LogEdit)
  cnt=TALLY(inpString,"~")
  FOR i=2 TO cnt
    tstr=FIELD$(inpString,"~",i)
    token=UCASE$(FIELD$(tstr," ",1))
    IF token="CREATE" THEN
      token=UCASE$(FIELD$(tstr," ",4))
      objType=ExtractObjectID(token)                          ' Not forms or menus or unknowns!
      call  AddClrString ("5971:objType="+str$(objType), cldr, LogEdit)
      IF (objType > 0) AND (objType < NON_VISIBLE) THEN
        frmString=frmString+tstr+"~"
      ELSE
        i=ExtractOther(i,inpString)                         ' Collect these incrementing our counter
      END IF
    ELSE
      frmString=frmString+tstr+"~"
    END IF
  NEXT i

  frmString=LEFT$(frmString,LEN(frmString)-1)                     ' Remove trailing "~"
  call  AddClrString ("5995:frmString="+str$(frmString), clred, LogEdit)
  FormsList=FormsList+frmString+"@"                               ' Add to global list
  call  AddClrString ("5997:FormsList="+str$(FormsList), clred, LogEdit)
END SUB

' Check an "external" component block (not inside a form) for known parent form
' If it belongs to a "DIM"ed form, then put it with "unknowns" list to ignore
'*****************************************
FUNCTION IsParentKnown(inpString AS string) AS integer
  DEFINT i, cnt
  DEFSTR tstr, FormName=""

  Result=False
  cnt=TALLY(inpString,"~")+1
  FOR i=2 TO cnt
    tstr=FIELD$(inpString,"~",i)
    IF UCASE$(LTRIM$(RTRIM$(FIELD$(tstr,"=",1))))="PARENT" THEN
      FormName=UCASE$(LTRIM$(RTRIM$(FIELD$(tstr,"=",2))))     ' Get this components parent name
      EXIT FOR
    END IF
  NEXT i
  IF FormName<>"" THEN                                            ' Check our form names
    cnt=TALLY(FormsList,"@")
    FOR i=1 TO cnt                                              ' Loop each of "known" forms
      tstr=LTRIM$(FIELD$(FormsList,"@",i))
      tstr=UCASE$(LTRIM$(RTRIM$(FIELD$(tstr," ",2))))         ' The form name
      IF tstr=FormName THEN
        Result=True                                         ' One of our "known" forms
        EXIT FOR
      END IF
    NEXT i
  END IF
END FUNCTION

'*****************************************
' Add "known" list object to form list
SUB AddToFormList(frmName AS string, objString AS string)
  DEFINT i, j, count, found=False
  DEFSTR tstr, frmString, resString=" "

  count=TALLY(FormsList,"@")
  FOR i=1 TO count                                                ' For each form in FormList
    frmString=TRIM$(FIELD$(FormsList,"@",i))
    tstr=UCASE$(TRIM$(FIELD$(frmString," ",2)))                 ' This form name
    IF tstr=frmName THEN                                        ' Need to add to this form?
      tstr=TRIM$(FIELD$(frmString,"~",1))                     ' First "CREATE..." field
      resString=resString+tstr+"~"
      FOR j=2 TO TALLY(frmString,"~")+1                       ' Get each field
        tstr=TRIM$(FIELD$(frmString,"~",j))
        SELECT CASE UCASE$(LEFT$(tstr,6))
        CASE "CREATE"                                   ' Child objects?
          IF found=False THEN                         ' First child object found?
            resString=resString+objString+"~"       ' Insert NEW object
            found=True
          END IF
          resString=resString+tstr+"~"                ' Continue with child object
        CASE "END CR"                                   ' End of Form code?
          IF found=False THEN                         ' NO child objects found?
            resString=resString+objString+"~"       ' Insert new object
            found=True
          END IF
          resString=resString+tstr+"~"                ' Add the terminater
        CASE ELSE
          resString=resString+tstr+"~"                ' Keep filling out the form string
        END SELECT
      NEXT j
    ELSE                                                        ' NOT parent form we are looking for
      resString=resString+frmString+"@"                       ' Add to resString
    END IF
    resString=LEFT$(resString,LEN(resString)-1)                 ' Remove trailing "~"
    resString=resString+"@"
  NEXT i
  FormsList=LTRIM$(resString)
END SUB

'*****************************************
' Move any objects from "known" list with Form parent to relevant formlist
SUB ParseTheKnowns
  DEFINT i, j, count
  DEFSTR tstr, objString, resString=" "

  count=TALLY(KnownsList,"@")
  FOR i=1 TO count
    objString=TRIM$(FIELD$(KnownsList,"@",i))
    IF IsParentKnown(objString) THEN                            ' Has it a parent form?
      FOR j=2 TO TALLY(objString,"~")+1
        tstr=UCASE$(TRIM$(FIELD$(objString,"~",j)))
        IF RTRIM$(FIELD$(tstr,"=",1))="PARENT" THEN
          tstr=UCASE$(LTRIM$(FIELD$(tstr,"=",2)))         ' Parent Form name
          objString=objString-(TRIM$(FIELD$(objString,"~",j))+"~")        ' Remove "parent=..." field
          AddToFormList(tstr,objString)                   ' Move it into the FormsList
          EXIT FOR
        END IF
      NEXT j
    ELSE
      resString=resString+objString+"@"                       ' Parent not specified - keep in knownsList
    END IF
  NEXT i
  KnownsList=LTRIM$(resString)
END SUB

'*****************************************
SUB CreateDebugFile
  DEFINT i
  DEFSTR tstr
  DIM sList AS QStringList

  sList.Clear
  FOR i=1 TO TALLY(FormsList,"@")
    tstr=FIELD$(FormsList,"@",i)
    sList.AddItems(tstr)
  NEXT i
  FOR i=1 TO TALLY(MainMenuList,"@")
    tstr=FIELD$(MainMenuList,"@",i)
    sList.AddItems(tstr)
  NEXT i
  FOR i=1 TO TALLY(PopMenuList,"@")
    tstr=FIELD$(PopMenuList,"@",i)
    sList.AddItems(tstr)
  NEXT i
  FOR i=1 TO TALLY(KnownsList,"@")
    tstr=FIELD$(KnownsList,"@",i)
    sList.AddItems(tstr)
  NEXT i
  FOR i=1 TO TALLY(UnknownList,"@")
    tstr=FIELD$(UnknownList,"@",i)
    sList.AddItems(tstr)
  NEXT i
  sList.SaveToFile("DbgInputStream.txt")
  sList.Clear
  ShowMessage "DBG: DbgInputStream.txt created!"
END SUB




' Parse and separate blocks of "create .. end create" in the first instance.
' Can be of type Form, Mainmenu, Popupmenu, standard component (with/out parent!) or "unknowns"
' Fill global string lists, ready for displaying forms & initialising menu editor etc

'*****************************************
SUB ParseInputStream
  call  AddClrString ("6112:ParseInputStream=", clg, LogEdit)

  exit sub '!!!===============================================

  DEFINT i, lev, cnt, objType
  DEFSTR tstr,tstr1, blkString, tmpblkString,
  DEFSTR CreateBlocks(1 TO MAX_OBJECTS)

  call  AddClrString ("6122:ProjectStream.LineCount="+str$(ProjectStream.LineCount), clred, LogEdit)

  FOR cnt=1 TO MAX_OBJECTS
    CreateBlocks(cnt)=""
  NEXT cnt
  blkString=" ": lev=0: cnt=0
  tmpblkString=" ":

  ProjectStream.Position=0
  FOR i=1 TO ProjectStream.LineCount
    tstr=ProjectStream.ReadLine
    'call  AddClrString ("6123:tstr="+(tstr), clred, LogEdit)
    tstr1=tstr
    tstr=ReformatLine(tstr)                                     '!!! "Pretty" the line for parsing
    'call  AddClrString ("6126:tstr="+(tstr), clred, LogEdit)
    call  AddClrString (tstr1, clBrown, RichEdit1)

    if instr(tstr,".Show")>0 then exit for '!!! <<<<<<<<<<<<<< неправильно!!! надо проверить

    IF tstr="" THEN                                             ' Do nothing
    ELSEIF UCASE$(FIELD$(tstr," ",1))="CREATE" THEN
      IF (cnt=0) AND (lev=0) THEN StartOfBlocks=i             ' Global Start Marker - line num of project code
      INC lev
      blkString=blkString+tstr+"~"                            ' Add the line to the block string
      tmpblkString=tmpblkString+tstr+"~"                            ' Add the line to the block string

    ELSEIF lev>0 THEN                                           ' Inside CREATE .. END CREATE
      blkString=blkString+tstr+"~"
      tmpblkString=tmpblkString+tstr+"~"

      IF (UCASE$(FIELD$(tstr," ",1))="END") THEN              ' End of current object
        DEC lev
        call  AddClrString ("6140:lev="+str$(lev), clred, LogEdit)
        call  AddClrString ("  ", clBrown, RichEdit1)

        IF lev=0 THEN                                       ' Was it the end of a block?
          EndOfBlocks=i                     'Line # of the end of block - Global End Marker updated until last block parsed
          call  AddClrString ("6143:EndOfBlocks="+str$(EndOfBlocks), clred, LogEdit)

          INC cnt
          call  AddClrString ("6145:cnt="+str$(cnt), clred, LogEdit)

          blkString=LEFT$(blkString,LEN(blkString)-1)+"@"     ' Replace trailing '~' with '@'
          tmpblkString=LEFT$(tmpblkString,LEN(tmpblkString)-1)+"@"     ' Replace trailing '~' with '@'

          kk%=LEN(tmpblkString)\1024+1
          call  AddClrString ("6156:kk%="+str$(kk%), clred, LogEdit)
          for ii%=0 to kk%
            call  AddClrString ("6158:ii%="+str$(ii%), clred, LogEdit)
            call  AddClrString (mid$(tmpblkString,1024*ii%,1024), cldr, LogEdit)
          next

          CreateBlocks(cnt)=LTRIM$(blkString)             ' Save until ready to display
          blkString=" "                                   ' Start again
          tmpblkString=" "                                   ' Start again
          'call  AddClrString ("6151:tmpblkString="+(tmpblkString), clred, LogEdit)
        END IF
      END IF
    END IF
  NEXT i

  ' !!! Parse all Form blocks first! =============================
  FOR i=1 TO cnt
    blkString=CreateBlocks(i)                                   ' Each create .. end create block
    tstr=FIELD$(blkString,"~",1)
    tstr=UCASE$(FIELD$(tstr," ",4))
    IF LEFT$(tstr,5)="QFORM" THEN                               ' Includes QFormEX!!
      tstr=LEFT$(blkString,LEN(blkString)-1)+"~"
      ParseForm(tstr)                                         ' Updates FormList global string
    END IF
  Next i

  ' Update remainder of global lists
  FOR i=1 TO cnt
    blkString=CreateBlocks(i)                                   ' Each create .. end create block
    tstr=FIELD$(blkString,"~",1)
    tstr=UCASE$(FIELD$(tstr," ",4))
    IF LEFT$(tstr,5)="QFORM" THEN                               ' Do nothing!
    ELSEIF tstr="QMAINMENU" THEN
      MainMenuList=LTRIM$(MainMenuList)+blkString             ' Main meus
    ELSEIF tstr="QPOPUPMENU" THEN
      PopMenuList=LTRIM$(PopMenuList)+blkString               ' Popup menus
    ELSE
      objType=ExtractObjectID(tstr)
      SELECT CASE objType
      CASE 1 TO (NON_VISIBLE-1)                           ' Visible objects (but not forms or menus)
        IF IsParentKnown(blkString) THEN
          KnownsList=KnownsList+blkString             ' Temporarily put into "knowns" list
        ELSE
          UnknownList=UnknownList+blkString           ' Put into the "unknowns" list
        END IF
      CASE NON_VISIBLE TO MAX_TOOLBTNS                    ' Non visible stuff
        KnownsList=KnownsList+blkString                 ' Put into "knowns" list
      CASE ELSE
        UnknownList=UnknownList+blkString               ' Put into the "unknowns" list
      END SELECT
    END IF
  NEXT i
  ParseTheKnowns                                                  ' Move objects with "known" parents into formslist

  $IFDEF DBG_INPUT_STREAM
  CreateDebugFile
  $ENDIF
END SUB

'--------------------------------Load Existing Project  --------------------------------
' Entry point LoadProject()
'---------------------------------------------------------------------------------------

'*****************************************
SUB LoadClipboardText
  DEFSTR tstr

  ClipBoard.Open
  tstr=ClipBoard.Text                                             ' Read contents
  ClipBoard.Clear                                                 ' Clear the clipboard!!
  ClipBoard.Close                                                 ' Finished with it for now
  DoEvents
  IF tstr="" THEN
    'MessageBox("The clipboard is empty - terminating!","RapidFRM "+VER,&h30)
    ErrorCondition=True
    'ProgramEnd
    exit sub
  ELSE
    ProjectStream.Close                                         ' Ensure initialised
    ProjectStream.WriteStr(tstr,LEN(tstr))
    ProjectStream.Position=0
  END IF
END SUB

'*****************************************
SUB LoadProjectFile
  'call  AddClrString ("6215:LoadProjectFile="+(ProjectFile), clg, LogEdit)
  DIM file AS QFILESTREAM
  DEFSTR tstr

  IF FileExists(ProjectFile)=0 THEN
    'MessageBox("File "+ProjectFile+" does not exist - terminating!","RapidFRM "+VER,&h30)
    ErrorCondition=True
    exit sub
    'ProgramEnd
  END IF

  tstr=UCASE$(RIGHT$(ProjectFile,4))
  SELECT CASE tstr
  CASE ".BAS",".RQB",".INC",".FRM"                            ' These file types accepted
  CASE ELSE
    tstr="Usage:"+CRLF+"RapidFRM.exe [<source file>]"+CRLF
    tstr=tstr+"Optional source file to be of type BAS, RQB, INC or FRM"
    MessageBox(tstr,"RapidFRM "+VER,&h40)
    ErrorCondition=True
    ProgramEnd
  END SELECT
  ProjectStream.Close                                             ' Ensure initialised
  file.Open(ProjectFile,fmOpenRead)
  ProjectStream.CopyFrom(file,0)                                  ' Copy all into memstream
  file.Close
  DoEvents
  ProjectStream.Position=0
END SUB

'*****************************************
SUB LoadProject
  'call  AddClrString ("6242:LoadProject="+str$(LoadProject), clg, LogEdit)
  IF ProjectMode=INPUT_CLIPBRD THEN                               ' Which input?
    LoadClipboardText
  ELSE
    LoadProjectFile
  END IF
  ParseInputStream
END SUB

'---------------------------- Exit program -----------------------------------------
' NB STAND_ALONE mode takes care of it's own Forward declarations and sub templates
'-----------------------------------------------------------------------------------

'*****************************************
' Not sure if this necessary, but...
SUB CleanUp
  DEFINT i
  DEFLNG hWnd
  DEFSTR tstr

  FOR i=1 TO ObjectIndex-1                                        ' Do not think RapidQ "knows" about...
    tstr=AddedObjectList(i)                                          ' ...the system memory used by component...
    IF tstr<>"" THEN                                            ' ...objects created at the "local" level
      tstr=FIELD$(tstr,"~",1)
      IF FIELD$(tstr,"|",1)<>"0" THEN                         ' NOT global forms, RapidQ will fix these
        hWnd=VAL(FIELD$(tstr,"|",3))
        DestroyWindow(hWnd)                                 ' Return memory to system
      END IF
    END IF
  NEXT i
END SUB

'*****************************************
' Default (button) for yes/no: 1=yes mask=0: 2=no mask=&h100
SUB ProgramEnd
  DEFSTR tstr
  DEFLNG mask=&h100                                                   ' Default to button 2 - NO

  IF ErrorCondition=False THEN
    IF ObjectIndex>ComponentCount THEN
      tstr="QUIT without saving changes?"
      IF MessageBox(tstr,"Project updated...",mask+&h24)=mrNo THEN EXIT SUB
    END IF
  END IF
  UnhookWindowsHookEx(hHook)                                      ' Remove our windows mouse hook
  CleanUp
  Application.Terminate
END SUB


'*****************************************
SUB AskExit
  IF MessageDlg("Save work before exiting?", mtWarning, mbYes OR mbNo, 0) = mrNo THEN
    ExitNoUpdate
  ELSE
    SaveAndExit
  END IF
END SUB


'*****************************************
SUB ExitNoUpdate
  DEFINT i
  DEFSTR tstr=""

  SELECT CASE ProjectMode
  CASE STAND_ALONE, INPUT_FILE
    ProgramEnd                                              ' Exit with confirmation
  CASE ELSE                                                   ' Clipboard must be re-instated
    ProjectStream.Position=0                                ' The original project stream
    FOR i=1 TO ProjectStream.LineCount
      tstr=tstr+ProjectStream.ReadLine+CRLF               ' Build original code
    NEXT i
    ClipBoard.Open: ClipBoard.Clear
    ClipBoard.Text=tstr                                     ' Add to the clipboard
    ClipBoard.Close
    DoEvents
    ErrorCondition=False: ObjectIndex=ComponentCount        ' 2 Conditions set to exit immediately
    ProgramEnd
  END SELECT
END SUB

'---------------------------- Saving a Project --------------------------------------
' Entry point SaveAndExit()
'------------------------------------------------------------------------------------

'*****************************************
' Format Create..End Create blocks that are not QFORMs
FUNCTION FmtOtherBlocks(inpStr AS string) AS string
  DEFINT i, cnt
  DEFSTR tstr, token, spacer="    "
  DEFSTR blkString

  cnt=TALLY(inpStr,"~")-1                                         ' (Lines-1) of code to add
  blkString=FIELD$(inpStr,"~",1)+CRLF                             ' Start with the create line
  FOR i=2 TO cnt                                                  ' Do the lines between create..end create
    tstr=FIELD$(inpStr,"~",i)
    token=FIELD$(tstr," ",1)
    SELECT CASE UCASE$(token)                                   ' Check for string data
    CASE "CAPTION", "TEXT", "HINT"
      token=LTRIM$(FIELD$(tstr,"=",2))                    ' Get the string value (no quotes!)
      token=QU+token+QU                                   ' Add the quotes
      tstr=RTRIM$(FIELD$(tstr,"=",1))                     ' Remove old
      tstr=tstr+" = "+token                               ' Insert new
    END SELECT
    tstr=spacer+tstr+CRLF                                       ' Add with indentation
    blkString=blkString+tstr
  NEXT i
  tstr=FIELD$(inpStr,"~",i)                                       ' Do last line
  blkString=blkString+tstr+CRLF
  Result=blkString
END FUNCTION

'*****************************************
SUB SaveAndExit
  DIM newStream AS QMEMORYSTREAM
  DIM NewFile AS QFILESTREAM
  DEFINT i, lev
  DEFSTR tstr, token

  IF DesignTab.TabIndex=3 THEN                                    ' FreeBasic?
    FB_SaveAndExit                                              ' Call separate code...
    EXIT SUB
  END IF

  'call  AddClrString ("5525:ProjectFile="+(ProjectFile), cldg, LogEdit)

  SaveAsOnClick

  ProjectFile=SaveDialog.FileName


  ' On entry we have the entire project file/clipboard data in the ProjectStream
  IF ProjectMode=INPUT_FILE THEN
    tstr=LEFT$(ProjectFile, RINSTR(ProjectFile,"."))+"bup"      ' Create a backup file name
    IF FileExists(tstr) THEN                                    ' Backup file exists?
      KILL tstr                                               ' Delete it
      DoEvents
    END IF
    RENAME(ProjectFile,tstr)                                    ' Backup original file
    DoEvents
  END IF

  ProjectStream.Position=0                                        ' The original project stream
  newStream.Close                                                 ' Ensure initialised
  FOR i=1 TO StartOfBlocks-1
    tstr=ProjectStream.ReadLine                                 ' Copy lines up to first block declaration
    newStream.WriteLine(tstr)
  NEXT i
  FOR i=i TO EndOfBlocks
    tstr=ProjectStream.ReadLine                                 ' Discard EXISTING block data
  NEXT i

  ' Add any new/changed forward declarations B4 we add the new code
  IF LTRIM$(FwdDeclares)<>"" THEN
    IF ProjectMode=INPUT_CLIPBRD THEN
      newStream.WriteLine("'FWD_DECL")                        ' Marker for IDE
    ELSE
      newStream.WriteLine("' Forward declarations")
    END IF
    FOR i=1 TO TALLY(FwdDeclares,"~")
      tstr=LTRIM$(RTRIM$(FIELD$(FwdDeclares,"~",i)))
      newStream.WriteLine("DECLARE "+tstr)                    ' Add the new line
    NEXT i
    newStream.WriteLine("")
  END IF
  ' Add the new form code
  IF ProjectMode=INPUT_CLIPBRD THEN
    newStream.WriteLine("'FRM_CODE")                            ' Marker for IDE
    '        newStream.WriteLine("' Code generated by RapidFRM "+VER)    ' Mark code with version info
    newStream.WriteLine("")
  END IF
  FOR i=0 TO CodeText.LineCount-1
    tstr=CodeText.Line(i)
    newStream.WriteLine(tstr)                                   ' Add the new code
  NEXT i
  ' Add any "Knowns" found (components without parents etc..)
  IF KnownsList<>"" THEN
    FOR i=1 TO TALLY(KnownsList,"@")
      tstr=FIELD$(KnownsList,"@",i)+"~"
      tstr=FmtOtherBlocks(tstr)                               ' Format the code
      newStream.WriteLine(tstr)                               ' Add the new code
    NEXT i
  END IF
  ' Re-insert any "unknowns" found
  IF UnknownList<>"" THEN
    FOR i=1 TO TALLY(UnknownList,"@")
      tstr=LTRIM$(FIELD$(UnknownList,"@",i))+"~"
      tstr=FmtOtherBlocks(tstr)                               ' Format the code
      newStream.WriteLine(tstr)                               ' Add the new code
    NEXT i
  END IF
  ' Add remainder of original project
  i=EndOfBlocks+1
  FOR i=i TO ProjectStream.LineCount
    tstr=ProjectStream.ReadLine
    newStream.WriteLine(tstr)
  NEXT i
  ' Add any new/changed event sub() stubs at end of file code
  IF LTRIM$(FwdDeclares)<>"" THEN                                 ' Anything to add?
    newStream.WriteLine("")
    IF ProjectMode=INPUT_CLIPBRD THEN
      newStream.WriteLine("'FRM_STUBS")                       ' Marker for IDE
    END IF
    FOR i=1 TO TALLY(FwdDeclares,"~")
      tstr=FIELD$(FwdDeclares,"~",i)
      newStream.WriteLine(LTRIM$(tstr))                       ' Add the sub..end sub
      newStream.WriteLine("END SUB")
      newStream.WriteLine("")
    NEXT i
  END IF

  IF ProjectMode=INPUT_FILE THEN
    NewFile.Open(ProjectFile, fmCreate)
    NewFile.CopyFrom(newStream,0)                               ' Copy all code into file
    NewFile.Close                                               ' Done

    tstr="Your project file has been saved."+CRLF+"Your original file was archived"
    MessageBox(tstr,"RapidFRM "+VER,&h40)
  ELSE
    newStream.Position=0: tstr=""
    FOR i=1 TO newStream.LineCount
      tstr=tstr+newStream.ReadLine+CRLF
    NEXT i
    ClipBoard.Open
    ClipBoard.Clear
    ClipBoard.Text=tstr
    ClipBoard.Close
  END IF
  ErrorCondition=False: ObjectIndex=ComponentCount                ' 2 Conditions set to exit immediately
  ProgramEnd
END SUB

'-----------------------------------------------------------------------------------------
'-----------------------------FreeBasic additions-----------------------------------------
' Main entry point for outputting FreeBasic code BuildFBCode()
'-----------------------------------------------------------------------------------------
'-----------------------------------------------------------------------------------------

'*****************************************
' Which components currently supported
FUNCTION FB_HasSupport(ObjType AS string) AS integer
  Result=True
  SELECT CASE ObjType
  CASE "QOUTLINE","QOLECONTAINER","QSPLITTER", _
    "QMYSQL","QOLEOBJECT","QREGISTRY", _
    "QDXTimer","QDXSound","QDXScreen","QDXImageList", _
    "QD3DFace","QD3DMeshBuilder","QD3DFrame","QD3DLight", _
   "QD3DTexture","QD3DVector","QD3DWrap"
    Result=False
  END SELECT
END FUNCTION

'*****************************************
' This component coded into project?
FUNCTION FB_HasComponent(ObjType AS string) AS integer
  DEFINT i

  FOR i=0 TO ObjCount-1
    IF ObjType=RTRIM$(FB_Objects(i).FBObjType) THEN
      Result=True
      EXIT FUNCTION
    END IF
  NEXT i
  Result=False
END FUNCTION

'*****************************************
' Match parent to child handles, even though they are only
' REAL at design time, we still match the actual objects ok!
FUNCTION FB_GetParentIdx(ChildIdx AS integer) AS integer
  DEFLNG pHandle
  DEFINT i

  Result=0                            ' Defaults to main form
  pHandle=FB_Objects(ChildIdx).FBObjParent
  FOR i=0 TO ChildIdx-1
    IF FB_Objects(i).FBObjHandle=pHandle THEN
      Result=i
      EXIT FOR
    END IF
  NEXT i
END FUNCTION

'*****************************************
FUNCTION FB_HasObjCaption(OType AS string) AS integer
  DEFSTR tstr

  Result=False
  tstr=UCASE$(LTRIM$(RTRIM$(OType)))
  SELECT CASE tstr
  CASE "QFORM","QLABEL","QBUTTON","QCOOLBTN","QOVALBTN", _
    "QGROUPBOX","QCHECKBOX","QRADIOBUTTON","QPANEL"
     Result=True
  END SELECT
END FUNCTION

'*****************************************
FUNCTION FB_ObjectVisible(idx AS integer) AS integer
  Result=False
  IF FB_Objects(idx).FBObjID < NON_VISIBLE THEN
    Result=True
  END IF
END FUNCTION

'*****************************************
SUB FB_FillHeader
  DEFSTR tstr

  FBCodeText.AddStrings "'-------------------------------------------------------------------------------"
  FBCodeText.AddStrings "' FreeBasic code generated by RapidFRM "+VER
  FBCodeText.AddStrings "'-------------------------------------------------------------------------------"
  FBCodeText.AddStrings "#INCLUDE "+QU+"windows.bi"+QU
  FBCodeText.AddStrings "#INCLUDE "+QU+"win/commctrl.bi"+QU
  FBCodeText.AddStrings "InitCommonControls()",""
  IF FB_HasComponent("QRICHEDIT") THEN
    FBCodeText.AddStrings "#DEFINE __QRICHEDIT"
    FBCodeText.AddStrings "#INCLUDE ONCE "+QU+"win/richedit.bi"+QU
    FBCodeText.AddStrings "DyLibLoad("+QU+"Riched32.dll"+QU+")",""
  END IF
  IF FB_HasComponent("QEDIT") THEN
    FBCodeText.AddStrings "#DEFINE __QEDIT"
    FBCodeText.AddStrings "#INCLUDE ONCE "+QU+"win/richedit.bi"+QU
  END IF
  IF FB_HasComponent("QDIRTREE") THEN
    FBCodeText.AddStrings "#DEFINE __QDIRTREE"
    FBCodeText.AddStrings "#INCLUDE ONCE "+QU+"win/shellapi.bi"+QU
  END IF
  IF FB_HasComponent("QSOCKET") THEN
    FBCodeText.AddStrings "#DEFINE __QSOCKET"
    FBCodeText.AddStrings "#INCLUDE ONCE "+QU+"win/winsock.bi"+QU
  END IF
  IF FB_HasComponent("QCOOLBTN") THEN FBCodeText.AddStrings "#DEFINE __QCOOLBTN"
  IF FB_HasComponent("QGAUGE") THEN FBCodeText.AddStrings "#DEFINE __QGAUGE"
  IF FB_HasComponent("QOVALBTN") THEN FBCodeText.AddStrings "#DEFINE __QOVALBTN"
  IF FB_HasComponent("QPANEL") THEN FBCodeText.AddStrings "#DEFINE __QPANEL"
  IF FB_HasComponent("QSCROLLBOX") THEN FBCodeText.AddStrings "#DEFINE __QSCROLLBOX"
  IF FB_HasComponent("QGROUPBOX") THEN FBCodeText.AddStrings "#DEFINE __QGROUPBOX"
  IF FB_HasComponent("QTABCONTROL") THEN FBCodeText.AddStrings "#DEFINE __QTABCONTROL"
  IF FB_HasComponent("QSTRINGGRID") THEN FBCodeText.AddStrings "#DEFINE __QSTRINGGRID"

  tstr=Application.Path
  IF FileExists(tstr+"\RQInclude.bi") THEN
    tstr=REPLACESUBSTR$(tstr,"\","/")
    FBCodeText.AddStrings "#INCLUDE "+QU+tstr+"/RQInclude.bi"+QU         ' RapidFRM path
  ELSE
    FBCodeText.AddStrings "#INCLUDE "+QU+"win/RQInclude.bi"+QU           ' Default FreeBASIC path
  END IF
END SUB

'*****************************************
SUB FB_AddGlobals
  DEFINT i
  DEFSTR tstr

  FBCodeText.AddStrings "", "'-------------------------------------------------------------------------------"
  FBCodeText.AddStrings "' Global data from Form designer sheet"
  FBCodeText.AddStrings "'-------------------------------------------------------------------------------"
  FOR i=0 TO ObjCount-1
    tstr="DIM SHARED AS "+RTRIM$(FB_Objects(i).FBObjType)
    FBCodeText.AddStrings tstr+" "+RTRIM$(FB_Objects(i).FBObjName)
    tstr=tstr+" PTR "+RTRIM$(FB_Objects(i).FBObjPtrName)
    FBCodeText.AddStrings tstr+" = @"+RTRIM$(FB_Objects(i).FBObjName)
  NEXT i
END SUB

'*****************************************
' Replace Event parameter 'BYREF Var AS QRECT' with FBs 'lpVar RECT PTR'
FUNCTION FixQRect(Txt AS string) AS string
  DEFSTR tstr, tok
  DEFINT i
  tstr=""
  FOR i=1 TO TALLY(Txt,",")+1
    tok=FIELD$(Txt,",",i)
    IF INSTR(tok,"QRECT")>0 THEN
      tok=LTRIM$(RTRIM$(FIELD$(tok,"AS",1)))
      tok=" lp"+tok+" AS RECT PTR"
    END IF
    tstr=tstr+tok+","
  NEXT i
  tstr=LEFT$(tstr,LEN(tstr)-1)+")"                ' Replace final comma with close sub bracket
  Result=tstr
END FUNCTION

'*****************************************
SUB FB_AddFwdDeclares
  DEFINT i, j, idx
  DEFSTR tstr, tok1, tok2
  DEFSTR MyFuncList=""

  FBCodeText.AddStrings "", "'-------------------------------------------------------------------------------"
  FBCodeText.AddStrings "' Forward declarations for component events "
  FBCodeText.AddStrings "'-------------------------------------------------------------------------------"
  i=0
  DO
    j=FB_Objects(i).FBLineNum+1
    FOR idx=j TO FB_InputList.ItemCount-1
      tstr=LTRIM$(RTRIM$(FB_InputList.Item(idx)))
      IF LEFT$(tstr,1)="#" THEN EXIT FOR
      IF LEFT$(tstr,2)="On" THEN
        tok1=FIELD$(tstr,"|",2)
        tok2=FIELD$(tstr,"|",3)
        IF tok1<>"" THEN
          IF INSTR(MyFuncList,tok1)=0 THEN
            MyFuncList=MyFuncList+","+tok1
            tok1="DECLARE SUB "+tok1
            IF tok2="" THEN
              tok1=tok1+"(Sender AS "+RTRIM$(FB_Objects(i).FBObjType)+")"
            ELSE
              IF INSTR(tok2,"QRECT")>0 THEN tok2=FixQRect(tok2)       ' Replace RapidQ QRECT with RECT
              tok1=tok1+LEFT$(tok2,LEN(tok2)-1)
              tok1=tok1+", Sender AS "+RTRIM$(FB_Objects(i).FBObjType)+")"
            END IF
            FBCodeText.AddStrings tok1
          END IF
        END IF
      END IF
    NEXT idx
    INC i
  LOOP UNTIL i >= ObjCount
END SUB

'*****************************************
FUNCTION FB_GetParam(startIdx AS integer, pField AS string) AS integer
  DEFSTR tstr
  DEFINT i

  Result=0
  FOR i=startIdx TO FB_InputList.ItemCount-1
    tstr=UCASE$(FB_InputList.Item(i))
    IF LEFT$(tstr,1)="#" THEN EXIT FOR
    IF FIELD$(tstr,"|",1)=pField THEN
      Result=i
      EXIT FOR
    END IF
  NEXT i
END FUNCTION

'*****************************************
SUB FB_FillConfiguration(idx AS integer)
  DEFINT i, newIdx, memIdx, Found=False
  DEFSTR newLine, memLine, newTok, fldTok, ObjType, lpObjName

  ObjType=RTRIM$(FB_Objects(idx).FBObjType)               ' Component type to add
  lpObjName=RTRIM$(FB_Objects(idx).FBObjPtrName)          ' and the ptr
  FBCodeText.AddStrings ""
  FBCodeText.AddStrings SPACE$(4)+lpObjName+"->ObjIndex = "+STR$(idx)
  newIdx=FB_Objects(idx).FBLineNum+1                      ' First property at line 2
  ComponentRef.Position=0: memIdx=0                       ' Reset the memorystream
  DO
    INC memIdx
    IF memIdx>ComponentRef.LineCount THEN
      ShowMessage("INTERNAL ERROR: Component not found!")
      EXIT SUB
    END IF
    memLine=ComponentRef.ReadLine
    IF FIELD$(memLine," ",3)=ObjType THEN Found=True    ' Next line is first property
  LOOP UNTIL Found=True
  DO
    newLine=RTRIM$(FB_InputList.Item(newIdx))           ' Property for NEW component
    IF LEFT$(newLine,1)="#" THEN EXIT SUB               ' New component property?
    IF LEFT$(newLine,1)="*" THEN EXIT DO                ' Property info finished
    memLine=ComponentRef.ReadLine                       ' DEFAULT property this component

    fldTok=FIELD$(newLine,"|",1)
    IF fldTok<>FIELD$(memLine,"|",1) THEN
      ShowMessage("INTERNAL ERROR: Property field mis-align")
      EXIT SUB
    END IF
    newTok=FIELD$(newLine,"|",4)
    IF newTok<>FIELD$(memLine,"|",4) THEN
      SELECT CASE UCASE$(RTRIM$(fldTok))
      CASE "PARENT"
        GOTO SkipProperty
      CASE "CAPTION","TEXT","HINT","SIMPLETEXT","DIRECTORY","DRIVE","MASK", _
        "FILENAME","INITIALDIR","FILTER","FONTNAME","NAME","BMP", _
       "ICON", "SEPARATOR"
        newTok=REPLACESUBSTR$(newTok,QU,"")     ' Remove IF exist then...
        newTok=QU+newTok+QU                     ' ...ENSURE they exist
      CASE "LEFT","TOP","WIDTH","HEIGHT"
        SELECT CASE ObjType                     ' NOT for these objects
        CASE "QHEADER","QSTATUSBAR"
          GOTO SkipProperty
        CASE "QCOMBOBOX"
          IF UCASE$(RTRIM$(fldTok))="HEIGHT" THEN GOTO SkipProperty
        END SELECT
      CASE "COLWIDTHS"
        FOR i=1 TO TALLY(newTok,",")+1
          FBCodeText.AddStrings SPACE$(4)+lpObjName+"->"+FIELD$(newLine,"|",1) _
          +"("+STR$(i-1)+") = "+FIELD$(newTok,",",i)
        NEXT i
        GOTO SkipProperty
      END SELECT
      FBCodeText.AddStrings SPACE$(4)+lpObjName+"->"+FIELD$(newLine,"|",1)+" = "+newTok
    END IF
    SkipProperty:
    INC newIdx
  LOOP UNTIL newIdx >= FB_InputList.ItemCount
  ' Add any object event calls ... OnClick, OnChange etc
  DO
    newLine=LTRIM$(RTRIM$(FB_InputList.Item(newIdx)))
    IF LEFT$(newLine,1)="#" THEN EXIT DO
    IF LEFT$(newLine,2)="On" THEN
      newTok=LTRIM$(RTRIM$(FIELD$(newLine,"|",2)))
      IF newTok<>"" THEN
        FBCodeText.AddStrings SPACE$(4)+lpObjName+"->"+FIELD$(newLine,"|",1)+" = CAST(ANY PTR, @"+newTok+")"
      END IF
    END IF
    INC newIdx
  LOOP UNTIL newIdx >= FB_InputList.ItemCount
END SUB

'*****************************************
SUB FB_ConfigureObjects
  DEFINT i
  DEFSTR lpObjName

  FBCodeText.AddStrings "", "'-------------------------------------------------------------------------------"
  FBCodeText.AddStrings "' Configure components"
  FBCodeText.AddStrings "'-------------------------------------------------------------------------------"
  FBCodeText.AddStrings "SUB ConfigureComponents"

  FOR i=0 TO ObjCount-1
    FB_FillConfiguration(i)                                     ' For each component
  NEXT i
  FBCodeText.AddStrings "","END SUB"
END SUB

SUB FB_AddNonVisible(idx AS integer)
  DEFSTR tstr, tok, parnt

  parnt=RTRIM$(FB_Objects(0).FBObjPtrName)+"->Handle"
  tstr=UCASE$(LTRIM$(RTRIM$(FB_Objects(idx).FBObjType)))
  tok=RTRIM$(FB_Objects(idx).FBObjPtrName)
  SELECT CASE tstr
  CASE "QTIMER"
    FBCodeText.AddStrings "","    "+tok+"->Parent="+parnt
    FBCodeText.AddStrings "    SetTimer("+parnt+", "+tok+"->ObjIndex, "+tok+"->Interval, 0)"
  CASE "QSOCKET"
    FBCodeText.AddStrings "","    "+tok+"->Parent="+parnt
    '        CASE "QBITMAP"
    '        etc etc but not all components
  END SELECT
END SUB

'
' Currently cannot handle arrays of strings in FreeBasic code generation
' So FUDGE it here and break up into single strings and add each individually.
' QHeader has a "section order" problem (insertafter directive) fudged here too!
'
'*****************************************
SUB FB_AddSubItems(idx AS integer)
  DEFSTR tstr, tok1, tok2, objPtr
  DEFINT i, j, cnt

  objPtr=RTRIM$(FB_Objects(idx).FBObjPtrName)
  tstr=RTRIM$(FB_Objects(idx).FBObjType)
  SELECT CASE tstr
  CASE "QTABCONTROL"
    ' My FUDGE! Add each TAB individually
    i=FB_Objects(idx).FBLineNum+1
    FOR i=i TO FB_InputList.ItemCount-1                         ' Scan this objects properties/methods etc
      tok1=FB_InputList.Item(i)
      IF LEFT$(tok1,1)="#" THEN EXIT SUB                      ' End of this object? Exit
      IF UCASE$(LEFT$(tok1,7))="ADDTABS" THEN                 ' Found it!
        tok2=TRIM$(FIELD$(tok1,"|",4))
        IF tok2 <> "" THEN
          cnt=TALLY(tok2,",")+1
          j=1
          DO
            tok1=FIELD$(tok2,",",j)
            IF INSTR(tok1,QU)>0 THEN
              tok1=REPLACESUBSTR$(tok1,QU,"")
            END IF
            tok1=TRIM$(tok1)
            tstr=SPACE$(4)+objPtr+"->AddTabs "+QU+tok1+QU
            FBCodeText.AddStrings tstr
            INC j
          LOOP UNTIL j>cnt
          EXIT SUB                                        ' Exit out of here
        END IF
      END IF
    NEXT i
  CASE "QLISTBOX","QCOMBOBOX","QLISTVIEW"
    i=FB_Objects(idx).FBLineNum+1
    FOR i=i TO FB_InputList.ItemCount-1                         ' Scan this objects properties/methods etc
      tok1=FB_InputList.Item(i)
      IF LEFT$(tok1,1)="#" THEN EXIT SUB
      IF UCASE$(LEFT$(tok1,10))="ADDCOLUMNS" THEN             ' QListView only
        tok2=TRIM$(FIELD$(tok1,"|",4))
        IF tok2 <> "" THEN
          cnt=TALLY(tok2,",")+1
          j=1
          DO
            tok1=FIELD$(tok2,",",j)
            IF INSTR(tok1,QU)>0 THEN
              tok1=REPLACESUBSTR$(tok1,QU,"")
            END IF
            tok1=TRIM$(tok1)
            FBCodeText.AddStrings SPACE$(4)+objPtr+"->AddColumns("+objPtr+"->Width\"+STR$(cnt)+"-1,"+QU+tok1+QU+")"
            INC j
          LOOP UNTIL j>cnt
        END IF
      END IF
      IF UCASE$(LEFT$(tok1,8))="ADDITEMS" THEN                ' QListView only
        tok2=TRIM$(FIELD$(tok1,"|",4))
        IF tok2 <> "" THEN
          cnt=TALLY(tok2,",")+1
          j=1
          DO
            tok1=FIELD$(tok2,",",j)
            IF INSTR(tok1,QU)>0 THEN
              tok1=REPLACESUBSTR$(tok1,QU,"")
            END IF
            tok1=TRIM$(tok1)
            FBCodeText.AddStrings SPACE$(4)+objPtr+"->AddItems "+QU+tok1+QU
            INC j
          LOOP UNTIL j>cnt
          EXIT SUB
        END IF
      END IF
    NEXT i
  CASE "QHEADER"
    i=FB_Objects(idx).FBLineNum+1
    FOR i=i TO FB_InputList.ItemCount-1                         ' Scan this objects properties/methods etc
      tok1=FB_InputList.Item(i)
      IF LEFT$(tok1,1)="#" THEN EXIT SUB
      IF UCASE$(LEFT$(tok1,11))="ADDSECTIONS" THEN
        tok2=TRIM$(FIELD$(tok1,"|",4))
        IF tok2 <> "" THEN
          cnt=TALLY(tok2,",")+1
          j=1
          DO
            tok1=FIELD$(tok2,",",j)
            IF INSTR(tok1,QU)>0 THEN
              tok1=REPLACESUBSTR$(tok1,QU,"")
            END IF
            tok1=TRIM$(tok1)
            tstr=SPACE$(4)+objPtr+"->AddSections "+QU+tok1+QU
            FBCodeText.AddStrings tstr
            INC j
          LOOP UNTIL j>cnt
          EXIT SUB
        END IF
      END IF
    NEXT i
  END SELECT
END SUB

'*****************************************
SUB FB_CreateObjects
  DEFINT j, cnt
  DEFSTR tstr, tok, parnt, ExtStyle

  FBCodeText.AddStrings "", "'-------------------------------------------------------------------------------"
  FBCodeText.AddStrings "' Create components"
  FBCodeText.AddStrings "'-------------------------------------------------------------------------------"
  FBCodeText.AddStrings "SUB CreateMainMenu"
  FBCodeText.AddStrings "END SUB",""
  FBCodeText.AddStrings "SUB CreatePopupMenus"
  FBCodeText.AddStrings "END SUB",""

  FBCodeText.AddStrings "SUB CreateComponents"
  FBCodeText.AddStrings "DIM AS UINT StdStyle, ExtStyle=0"
  FBCodeText.AddStrings "DIM AS string ObjCaption",""
  ' Do the form
  tok=RTRIM$(FB_Objects(0).FBObjPtrName)
  FBCodeText.AddStrings SPACE$(4)+tok+"->PreSetConfig()"
  FBCodeText.AddStrings SPACE$(4)+"StdStyle="+tok+"->objStyle"
  FBCodeText.AddStrings SPACE$(4)+"IF "+tok+"->BorderStyle > bsDialog THEN ExtStyle=WS_EX_TOOLWINDOW",""
  FBCodeText.AddStrings SPACE$(4)+tok+"->Handle = CreateWindowEx(ExtStyle, "+QU+ _
  "RQClass"+QU+", "+tok+"->Caption, StdStyle, _"
  FBCodeText.AddStrings SPACE$(20)+tok+"->Left, "+tok+"->Top, "+tok+"->Width, "+tok+"->Height, _"
  FBCodeText.AddStrings SPACE$(20)+"0, 0, Application.hInstance, 0)"
  FBCodeText.AddStrings SPACE$(4)+"Application.hMainForm = "+tok+"->Handle"
  FBCodeText.AddStrings SPACE$(4)+tok+"->PostConfig()"
  cnt=1
  WHILE cnt < ObjCount
    IF FB_ObjectVisible(cnt) THEN
      tstr=RTRIM$(FB_Objects(cnt).FBObjPtrName)
      tok=SPACE$(4)+tstr+"->PreSetConfig()"                           ' Any pre-configuration?
      FBCodeText.AddStrings "",tok
      ' This object have a caption?
      IF FB_HasObjCaption(FB_Objects(cnt).FBObjType) THEN
        tok=SPACE$(4)+"ObjCaption="+tstr+"->Caption"                ' Set caption in code
      ELSE
        tok=SPACE$(4)+"ObjCaption="+QU+QU                           ' No caption this object
      END IF
      FBCodeText.AddStrings tok
      ' Get the parent of this object fm MyObjects struc
      j=FB_GetParentIdx(cnt)
      IF UCASE$(RTRIM$(FB_Objects(j).FBObjType))="QSCROLLBOX" THEN    ' Parent scrollbox?
        parnt=RTRIM$(FB_Objects(j).FBObjPtrName)+"->PanHandle"      ' The embedded panel not scrollbox
      ELSE
        parnt=RTRIM$(FB_Objects(j).FBObjPtrName)+"->Handle"         ' The objects parent
      END IF
      ' Accumulate window style parms
      tok=SPACE$(4)+"StdStyle="+tstr+"->objStyle"
      FBCodeText.AddStrings tok
      tok=SPACE$(4)+"IF "+tstr+"->Visible THEN StdStyle OR= WS_VISIBLE"
      FBCodeText.AddStrings tok
      SELECT CASE FB_Objects(cnt).FBObjID
      CASE Q_EDIT,Q_RICHEDIT,Q_LISTBOX,Q_SCROLLBOX,Q_DIRTREE,Q_LISTVIEW,Q_TREEVIEW         ' Any more?
        tok="IF "+tstr+"->BorderStyle=bsNone THEN ExtStyle=0 ELSE ExtStyle=WS_EX_CLIENTEDGE"
        FBCodeText.AddStrings SPACE$(4)+tok,""
      CASE Q_FILELISTBOX
        FBCodeText.AddStrings SPACE$(4)+"ExtStyle=WS_EX_CLIENTEDGE",""
      CASE ELSE
        FBCodeText.AddStrings SPACE$(4)+"ExtStyle=0",""
      END SELECT
      tok=SPACE$(4)+tstr+"->Handle=CreateWindowEx(ExtStyle,"
      tok=tok+tstr+"->objClass, ObjCaption, WS_CHILD OR StdStyle, _"
      FBCodeText.AddStrings tok
      tok=SPACE$(20)+tstr+"->Left, "+tstr+"->Top, "+tstr+"->Width, "+tstr+"->Height, _"
      FBCodeText.AddStrings tok
      tok=SPACE$(20)+parnt+", CAST(HMENU, "+tstr+"->objIndex), 0, 0)"
      FBCodeText.AddStrings tok, ""
      FBCodeText.AddStrings SPACE$(4)+tstr+"->Parent = "+parnt
      FB_AddSubItems(cnt)                                             ' Any additional config?
      tok=SPACE$(4)+tstr+"->PostConfig()"                             ' Any post-configuration?
      FBCodeText.AddStrings tok
      FBCodeText.AddStrings SPACE$(4)+"EnableWindow("+tstr+"->Handle, "+tstr+"->Enabled)"
    ELSE
      FB_AddNonVisible(cnt)
    END IF
    INC cnt
  WEND
  FBCodeText.AddStrings "", SPACE$(4)+"CreateMainMenu()"
  FBCodeText.AddStrings SPACE$(4)+"CreatePopupMenus()"
  FBCodeText.AddStrings "END SUB"
END SUB

'*****************************************
SUB FB_KillTimerCode
  DEFINT i
  DEFSTR tstr, tok1, tok2

  tok1=RTRIM$(FB_Objects(0).FBObjPtrName)                         ' Main form ptr
  FBCodeText.AddStrings "SUB KillAllTimers"
  FBCodeText.AddStrings SPACE$(4)+"KillTimer(Application.hMainForm, SYS_TIMER_IDX)"
  FOR i=1 TO ObjCount-1
    tstr=UCASE$(RTRIM$(FB_Objects(i).FBObjType))
    IF tstr="QTIMER" THEN
      tok2=RTRIM$(FB_Objects(i).FBObjPtrName)
      FBCodeText.AddStrings SPACE$(4)+tok2+"->Enabled=False"
      FBCodeText.AddStrings SPACE$(4)+"KillTimer("+tok1+"->Handle, "+tok2+"->ObjIndex)"
    END IF
  NEXT i
  FBCodeText.AddStrings "END SUB"
END SUB

'*****************************************
SUB FB_SysCheckHints
  DEFINT i
  DEFSTR tstr, tok

  FBCodeText.AddStrings "SUB CheckSystemTimers"
  FBCodeText.AddStrings "STATIC AS HWND TT_LastHWND"
  FBCodeText.AddStrings "DIM AS HWND TT_hWnd"
  FBCodeText.AddStrings "DIM AS Point TT_pnt",""
  FBCodeText.AddStrings SPACE$(4)+"TT_pnt.X=Screen.MouseX: TT_pnt.Y=Screen.MouseY"
  FBCodeText.AddStrings SPACE$(4)+"TT_hWnd=WindowFromPoint(TT_pnt)"
  FBCodeText.AddStrings SPACE$(4)+"IF TT_LastHWND<>TT_hWnd THEN"
  FBCodeText.AddStrings SPACE$(8)+"TT_LastHWND=TT_hWnd"
  FBCodeText.AddStrings SPACE$(8)+"SELECT CASE TT_hWnd"
  FOR i=0 TO ObjCount-1
    IF FB_ObjectVisible(i) THEN
      tstr=RTRIM$(FB_Objects(i).FBObjPtrName)
      FBCodeText.AddStrings SPACE$(12)+"CASE "+tstr+"->Handle"
      FBCodeText.AddStrings SPACE$(16)+"IF "+tstr+"->ShowHint THEN"
      FBCodeText.AddStrings SPACE$(20)+"SysDisplayHint("+tstr+"->Handle, "+tstr+"->Hint)"
      FBCodeText.AddStrings SPACE$(16)+"END IF"
    END IF
  NEXT i
  FBCodeText.AddStrings SPACE$(8)+"END SELECT"
  FBCodeText.AddStrings SPACE$(4)+"END IF"
  FBCodeText.AddStrings "END SUB"
END SUB

'*****************************************
SUB FB_FillTimerEvents
  DEFINT i, AddEm=False
  DEFSTR tstr, tok

  FBCodeText.AddStrings "","SUB CheckWmTimers(hWnd AS HWND, wMsg AS UINT, wParam AS WPARAM, lParam AS LPARAM)"
  FBCodeText.AddStrings SPACE$(4)+"SELECT CASE wParam"
  FBCodeText.AddStrings SPACE$(8)+"CASE App_Timer.ObjIndex:  CheckSystemTimers"

  FOR i=1 TO ObjCount-1
    tstr=UCASE$(RTRIM$(FB_Objects(i).FBObjType))
    IF tstr="QTIMER" THEN                                           ' Any user timers?????
      Addem=True
      EXIT FOR
    END IF
  NEXT i
  IF AddEm THEN
    FOR i=1 TO ObjCount-1
      tstr=UCASE$(RTRIM$(FB_Objects(i).FBObjType))
      IF tstr="QTIMER" THEN
        tok=RTRIM$(FB_Objects(i).FBObjPtrName)
        FBCodeText.AddStrings SPACE$(8)+"CASE "+tok+"->ObjIndex"
        FBCodeText.AddStrings SPACE$(12)+"IF ("+tok+"->Enabled) AND ("+tok+"->OnTimer>0) THEN"
        FBCodeText.AddStrings SPACE$(16)+tok+"->OnTimer("+tok+")"
        FBCodeText.AddStrings SPACE$(12)+"END IF"
      END IF
    NEXT i
  END IF
  FBCodeText.AddStrings SPACE$(4)+"END SELECT"
  FBCodeText.AddStrings "END SUB"
END SUB

'*****************************************
SUB FB_FillCmdEvents
  DEFINT i, ID, Addem=False
  DEFSTR tstr, tok

  FBCodeText.AddStrings "","SUB CheckWmCommandMsg(wParam AS WPARAM, lParam AS LPARAM)"
  FOR i=1 TO ObjCount-1
    ID=FB_Objects(i).FBObjID
    SELECT CASE ID
    CASE Q_EDIT,Q_RICHEDIT,Q_LABEL,Q_BUTTON,Q_COOLBTN,Q_OVALBTN,Q_CHECKBOX, _
    Q_RADIOBUTTON,Q_PANEL,Q_SCROLLBOX,Q_CANVAS,Q_IMAGE,Q_LISTBOX, _
   Q_FILELISTBOX,Q_COMBOBOX,Q_GROUPBOX
      Addem=True
      EXIT FOR
    END SELECT
  NEXT i
  IF Addem=False THEN
    FBCodeText.AddStrings "END SUB"
    EXIT SUB
  END IF

  FBCodeText.AddStrings SPACE$(4)+"SELECT CASE LOWORD(wParam)"
  FOR i=1 TO ObjCount-1
    ID=FB_Objects(i).FBObjID
    SELECT CASE ID
    CASE Q_EDIT,Q_RICHEDIT
      tok=RTRIM$(FB_Objects(i).FBObjPtrName)                ' eg lpForm1
      FBCodeText.AddStrings SPACE$(8)+"CASE "+tok+"->ObjIndex"
      FBCodeText.AddStrings SPACE$(12)+"IF "+tok+"->OnChange>0 THEN "+tok+"->OnChange("+tok+")"
    CASE Q_LABEL,Q_BUTTON,Q_COOLBTN,Q_OVALBTN,Q_CHECKBOX,Q_RADIOBUTTON,Q_PANEL,Q_SCROLLBOX,Q_CANVAS,Q_IMAGE,Q_GROUPBOX
      tok=RTRIM$(FB_Objects(i).FBObjPtrName)                ' eg lpForm1
      FBCodeText.AddStrings SPACE$(8)+"CASE "+tok+"->ObjIndex"
      FBCodeText.AddStrings SPACE$(12)+"IF "+tok+"->OnClick>0 THEN "+tok+"->OnClick("+tok+")"
    CASE Q_LISTBOX,Q_FILELISTBOX
      tok=RTRIM$(FB_Objects(i).FBObjPtrName)
      FBCodeText.AddStrings SPACE$(8)+"CASE "+tok+"->ObjIndex"
      FBCodeText.AddStrings SPACE$(12)+"IF HIWORD(wParam)=LBN_SELCHANGE THEN"
      FBCodeText.AddStrings SPACE$(16)+"IF "+tok+"->OnClick>0 THEN "+tok+"->OnClick("+tok+")"
      FBCodeText.AddStrings SPACE$(12)+"END IF"
      FBCodeText.AddStrings SPACE$(12)+"IF HIWORD(wParam)=LBN_DBLCLK THEN"
      FBCodeText.AddStrings SPACE$(16)+"IF "+tok+"->OnDblClick>0 THEN "+tok+"->OnDblClick("+tok+")"
      FBCodeText.AddStrings SPACE$(12)+"END IF"
    CASE Q_COMBOBOX
      tok=RTRIM$(FB_Objects(i).FBObjPtrName)
      FBCodeText.AddStrings SPACE$(8)+"CASE "+tok+"->ObjIndex"
      FBCodeText.AddStrings SPACE$(12)+"IF HIWORD(wParam)=CBN_SELCHANGE THEN"
      FBCodeText.AddStrings SPACE$(16)+"IF "+tok+"->OnChange>0 THEN "+tok+"->OnChange("+tok+")"
      FBCodeText.AddStrings SPACE$(12)+"END IF"
    END SELECT
  NEXT i
  FBCodeText.AddStrings SPACE$(4)+"END SELECT"
  FBCodeText.AddStrings "END SUB"
END SUB

'*****************************************
SUB FB_FillNotifyEvents
  DEFINT i, Addem=False
  DEFSTR tstr, tok

  FBCodeText.AddStrings "","SUB CheckWmNotifyMsg(wParam AS WPARAM, lParam AS LPARAM)"

  FOR i=1 TO ObjCount-1
    tstr=UCASE$(RTRIM$(FB_Objects(i).FBObjType))
    SELECT CASE tstr
    CASE "QTABCONTROL","QTRACKBAR","QHEADER","QLISTVIEW","QDIRTREE","QTREEVIEW","QPAGESCROLLER"
      Addem=True
      EXIT FOR
    END SELECT
  NEXT i
  IF AddEm THEN
    FBCodeText.AddStrings "DIM AS NMHDR PTR lpNmhdr=CAST(NMHDR PTR, lParam)"
    FBCodeText.AddStrings "",SPACE$(4)+"SELECT CASE lpNmhdr->hwndFrom"
    FOR i=1 TO ObjCount-1
      tstr=UCASE$(RTRIM$(FB_Objects(i).FBObjType))
      tok=RTRIM$(FB_Objects(i).FBObjPtrName)
      SELECT CASE tstr
      CASE "QTABCONTROL"
        FBCodeText.AddStrings SPACE$(8)+"CASE "+tok+"->Handle"
        FBCodeText.AddStrings SPACE$(12)+"IF lpNmhdr->Code=TCN_SELCHANGE THEN"
        FBCodeText.AddStrings SPACE$(16)+"IF "+tok+"->OnChange>0 THEN "+tok+"->OnChange("+tok+")"
        FBCodeText.AddStrings SPACE$(12)+"END IF"
      CASE "QTRACKBAR"
        FBCodeText.AddStrings SPACE$(8)+"CASE "+tok+"->Handle"
        FBCodeText.AddStrings SPACE$(12)+"IF lpNmhdr->code=NM_RELEASEDCAPTURE THEN"
        FBCodeText.AddStrings SPACE$(16)+tok+"->Position=SendMessage("+tok+"->Handle, TBM_GETPOS, 0, 0)"
        FBCodeText.AddStrings SPACE$(16)+"IF "+tok+"->OnChange>0 THEN "+tok+"->OnChange("+tok+")"
        FBCodeText.AddStrings SPACE$(12)+"END IF"
      CASE "QHEADER"
        FBCodeText.AddStrings SPACE$(8)+"CASE "+tok+"->Handle"
        FBCodeText.AddStrings SPACE$(12)+"IF lpNmhdr->code = HDN_ITEMCLICK THEN              ' Left button?"
        FBCodeText.AddStrings SPACE$(16)+"DIM AS NMHEADER PTR lpNmHead=CAST(NMHEADER PTR, lParam)"
        tstr="IF "+tok+"->OnSectionClick>0 THEN "+tok+"->OnSectionClick(lpNmHead->iItem, "+tok+")"
        FBCodeText.AddStrings SPACE$(16)+tstr
        FBCodeText.AddStrings SPACE$(12)+"END IF"
      CASE "QLISTVIEW"
        FBCodeText.AddStrings SPACE$(8)+"CASE "+tok+"->Handle"
        FBCodeText.AddStrings SPACE$(12)+"DIM AS NMITEMACTIVATE PTR lpItmActiv=CAST(NMITEMACTIVATE PTR, lParam)"
        FBCodeText.AddStrings SPACE$(12)+"IF (lpNmhdr->code=NM_CLICK) AND (lpItmActiv->iItem > -1) THEN"
        FBCodeText.AddStrings SPACE$(16)+tok+"->ItemIndex=lpItmActiv->iItem"
        FBCodeText.AddStrings SPACE$(16)+"IF "+tok+"->OnClick>0 THEN "+tok+"->OnClick("+tok+")"
        FBCodeText.AddStrings SPACE$(12)+"END IF"
        FBCodeText.AddStrings SPACE$(12)+"IF (lpNmhdr->code=NM_DBLCLK) AND (lpItmActiv->iItem > -1) THEN"
        FBCodeText.AddStrings SPACE$(16)+tok+"->ItemIndex=lpItmActiv->iItem"
        FBCodeText.AddStrings SPACE$(16)+"IF "+tok+"->OnDblClick>0 THEN "+tok+"->OnDblClick("+tok+")"
        FBCodeText.AddStrings SPACE$(12)+"END IF"
        FBCodeText.AddStrings SPACE$(12)+"IF (lpNmhdr->code=LVN_COLUMNCLICK) AND (lpItmActiv->iItem = -1) AND _"
        FBCodeText.AddStrings SPACE$(64)+"("+tok+"->ColumnClick=True) THEN"
        tstr="IF "+tok+"->OnColumnClick>0 THEN "+tok+"->OnColumnClick(lpItmActiv->iSubItem, "+tok+")"
        FBCodeText.AddStrings SPACE$(16)+tstr
        FBCodeText.AddStrings SPACE$(12)+"END IF"
      CASE "QDIRTREE"
        FBCodeText.AddStrings SPACE$(8)+"CASE "+tok+"->Handle"
        FBCodeText.AddStrings SPACE$(12)+"IF lpNmhdr->code=TVN_SELCHANGED THEN"
        FBCodeText.AddStrings SPACE$(16)+tok+"->UpdateTreeView(lParam)"
        FBCodeText.AddStrings SPACE$(16)+"IF "+tok+"->OnChange>0 THEN "+tok+"->OnChange("+tok+")"
        FBCodeText.AddStrings SPACE$(12)+"END IF"
      CASE "QTREEVIEW"
        FBCodeText.AddStrings SPACE$(8)+"CASE "+tok+"->Handle"
        FBCodeText.AddStrings SPACE$(12)+"SELECT CASE lpNmhdr->code"
        FBCodeText.AddStrings SPACE$(16)+"CASE TVN_SELCHANGED                 ' NOT NM_CLICK!"
        FBCodeText.AddStrings SPACE$(20)+tok+"->UpdateTreeView(lParam)"
        FBCodeText.AddStrings SPACE$(20)+"IF "+tok+"->OnClick>0 THEN "+tok+"->OnClick("+tok+")"
        FBCodeText.AddStrings SPACE$(16)+"CASE NM_DBLCLK"
        FBCodeText.AddStrings SPACE$(20)+"IF "+tok+"->OnDblClick>0 THEN "+tok+"->OnDblClick("+tok+")"
        FBCodeText.AddStrings SPACE$(12)+"END SELECT"
      CASE "QPAGESCROLLER"
        FBCodeText.AddStrings SPACE$(8)+"CASE "+tok+"->Handle"
        FBCodeText.AddStrings SPACE$(12)+"IF lpNmhdr->Code=PGN_CALCSIZE THEN"
        FBCodeText.AddStrings SPACE$(16)+"ShowMessage("+QU+"Here"+QU+")"
        FBCodeText.AddStrings SPACE$(12)+"END IF"
      END SELECT
    NEXT i
    FBCodeText.AddStrings SPACE$(4)+"END SELECT"
  END IF
  FBCodeText.AddStrings "END SUB"
END SUB

'*****************************************
SUB FB_FillPaintEvents
  DEFINT i, AddEm=False
  DEFSTR tstr, tok

  FBCodeText.AddStrings "","SUB CheckWmPaintMsg(hWnd AS HWND, wMsg AS UINT, wParam AS WPARAM, lParam AS LPARAM)"
  ' Any Components need auto re-sizing?
  FOR i=1 TO ObjCount-1
    tstr=UCASE$(RTRIM$(FB_Objects(i).FBObjType))
    SELECT CASE tstr
    CASE "QHEADER","QSTATUSBAR","QTOOLBAR"
      AddEm=True
      EXIT FOR
    END SELECT
  NEXT i
  IF AddEm=True THEN
    FBCodeText.AddStrings "DIM AS RECT frmRect"
    FBCodeText.AddStrings "DIM AS integer H, W",""
    FBCodeText.AddStrings SPACE$(4)+"GetClientRect(hWnd, @frmRect)"
    FBCodeText.AddStrings SPACE$(4)+"W=frmRect.Right-frmRect.Left"
    FOR i=1 TO ObjCount-1
      tstr=UCASE$(RTRIM$(FB_Objects(i).FBObjType))
      SELECT CASE tstr
      CASE "QHEADER","QTOOLBAR"                                           ' Default align to the top
        tok=RTRIM$(FB_Objects(i).FBObjPtrName)
        FBCodeText.AddStrings "", SPACE$(4)+"H="+tok+"->Height"
        FBCodeText.AddStrings SPACE$(4)+"MoveWindow("+tok+"->Handle, 0, 0, W, H, 1)"
        IF tstr="QHEADER" THEN
          FBCodeText.AddStrings SPACE$(4)+"IF "+tok+"->OnResize>0 THEN "+tok+"->OnResize("+tok+")"
        END IF

      CASE "QSTATUSBAR"                                                   ' Default align to the bottom
        tok=RTRIM$(FB_Objects(i).FBObjPtrName)
        '                    FBCodeText.AddStrings "", SPACE$(4)+"IF "+tok+"->SizeGrip THEN"
        FBCodeText.AddStrings "", SPACE$(4)+"H="+tok+"->Height"
        FBCodeText.AddStrings SPACE$(4)+"MoveWindow("+tok+"->Handle, 0, frmRect.Bottom-H, W, H, 1)"
        FBCodeText.AddStrings SPACE$(4)+"IF "+tok+"->OnResize>0 THEN "+tok+"->OnResize("+tok+")"
        '                    FBCodeText.AddStrings SPACE$(4)+"END IF"
      END SELECT
    NEXT i
    FBCodeText.AddStrings ""
  END IF
  tstr=RTRIM$(FB_Objects(0).FBObjPtrName)                                         ' Main form
  FBCodeText.AddStrings SPACE$(4)+"IF "+tstr+"->OnPaint>0 THEN "+tstr+"->OnPaint("+tstr+")"
  FBCodeText.AddStrings "END SUB"
END SUB

'*****************************************
' Currently not used
SUB FB_FillHitTestEvents
  FBCodeText.AddStrings "","SUB CheckWmHitTest(hWnd AS HWND, wMsg AS UINT, wParam AS WPARAM, lParam AS LPARAM)"
  FBCodeText.AddStrings "END SUB"
END SUB

'*****************************************
' ScrollBar object as child object of a parent (form)
SUB FB_FillScrollItems
  DEFSTR tstr, tok, objPtr
  DEFINT i, Addem=False

  FBCodeText.AddStrings "","SUB CheckWmObjScroll(hWnd AS HWND, wMsg AS UINT, wParam AS WPARAM, lParam AS LPARAM)"
  FOR i=1 TO ObjCount-1
    tstr=UCASE$(RTRIM$(FB_Objects(i).FBObjType))
    SELECT CASE tstr
    CASE "QSCROLLBAR"
      Addem=True
      EXIT FOR
    END SELECT
  NEXT i
  IF Addem THEN
    FBCodeText.AddStrings "DIM AS integer Posn",""
    FBCodeText.AddStrings SPACE$(4)+"SELECT CASE lParam"
    FOR i=1 TO ObjCount-1
      tstr=UCASE$(RTRIM$(FB_Objects(i).FBObjType))
      IF tstr="QSCROLLBAR" THEN
        objPtr=RTRIM$(FB_Objects(i).FBObjPtrName)
        FBCodeText.AddStrings SPACE$(8)+"CASE "+objPtr+"->Handle"
        FBCodeText.AddStrings SPACE$(12)+"Posn=GetScrollPos("+objPtr+"->Handle, SB_CTL)"
        FBCodeText.AddStrings SPACE$(12)+"SELECT CASE LOWORD(wParam)             ' independent of orientation"
        FBCodeText.AddStrings SPACE$(16)+"CASE SB_LINERIGHT,SB_LINEDOWN : Posn += "+objPtr+"->SmallChange"
        FBCodeText.AddStrings SPACE$(16)+"CASE SB_PAGERIGHT,SB_PAGEDOWN : Posn += "+objPtr+"->LargeChange"
        FBCodeText.AddStrings SPACE$(16)+"CASE SB_LINELEFT,SB_LINEUP    : Posn -= "+objPtr+"->SmallChange"
        FBCodeText.AddStrings SPACE$(16)+"CASE SB_PAGELEFT,SB_PAGEUP    : Posn -= "+objPtr+"->LargeChange"
        FBCodeText.AddStrings SPACE$(12)+"END SELECT"
        FBCodeText.AddStrings SPACE$(12)+"IF Posn > "+objPtr+"->Max THEN Posn = "+objPtr+"->Max"
        FBCodeText.AddStrings SPACE$(12)+"IF Posn < "+objPtr+"->Min THEN Posn = "+objPtr+"->Min"
        FBCodeText.AddStrings SPACE$(12)+objPtr+"->Position=Posn           ' Update the ScrollBar"
        FBCodeText.AddStrings SPACE$(12)+"IF "+objPtr+"->OnChange>0 THEN "+objPtr+"->OnChange("+objPtr+")"
      END IF
    NEXT i
    FBCodeText.AddStrings SPACE$(4)+"END SELECT"
  END IF
  FBCodeText.AddStrings "END SUB"
END SUB

'*****************************************
' NOT used - NO Button style components are OWNERDRAW style
SUB FB_CtlColorBtn
  DEFSTR tstr, objPtr
  DEFINT i, Addem=False

  FBCodeText.AddStrings "","FUNCTION CheckBtnColor(wParam AS WPARAM, lParam AS LPARAM) AS LRESULT"
  FBCodeText.AddStrings "DIM AS HBRUSH hBrush=NULL"
  FBCodeText.AddStrings "' Only for OwnerDraw buttons"
  ' DIM AS HDC hDC=CAST(HDC, wParam)
  ' DIM AS HWND Handle=CAST(HWND, lParam)

  '     SELECT CASE Handle
  '         CASE Obj->Handle                                   ' Obj = BUTTON-TYPE object
  '             SetBKMode(hDC, 1)
  '             SetTextColor(hDC, CAST(COLORREF, Obj->Font.Color))
  '             hBrush=CreateSolidBrush(CAST(COLORREF, Obj->Color))
  '     END SELECT
  FBCodeText.AddStrings SPACE$(4)+"RETURN CAST(LRESULT, hBrush)"
  FBCodeText.AddStrings "END FUNCTION"
END SUB


'*****************************************
' Sets color (background & text) for edit controls (NOT RichEdit) and ComboBox
SUB FB_CtlColorEdit
  DEFSTR tstr, objPtr
  DEFINT i, Addem=False

  FBCodeText.AddStrings "","FUNCTION CheckEditColor(wParam AS WPARAM, lParam AS LPARAM) AS LRESULT"
  FBCodeText.AddStrings "DIM AS HBRUSH hBrush=NULL"
  FOR i=1 TO ObjCount-1
    tstr=UCASE$(RTRIM$(FB_Objects(i).FBObjType))
    SELECT CASE tstr
    CASE "QEDIT", "QCOMBOBOX"                                       ' Edit panel of a combobox!
      Addem=True
      EXIT FOR
    END SELECT
  NEXT i
  IF Addem THEN
    FBCodeText.AddStrings "DIM AS HDC hDC=CAST(HDC, wParam)"
    FBCodeText.AddStrings "DIM AS HWND Handle=CAST(HWND, lParam)",""
    FBCodeText.AddStrings SPACE$(4)+"SELECT CASE Handle"
    FOR i=1 TO ObjCount-1
      tstr=UCASE$(RTRIM$(FB_Objects(i).FBObjType))
      IF tstr="QEDIT" THEN
        objPtr=RTRIM$(FB_Objects(i).FBObjPtrName)
        FBCodeText.AddStrings SPACE$(8)+"CASE "+objPtr+"->Handle"
        FBCodeText.AddStrings SPACE$(12)+"SetBKMode(hDC, 1)"
        FBCodeText.AddStrings SPACE$(12)+"SetTextColor(hDC, CAST(COLORREF, "+objPtr+"->Font.Color))"
        FBCodeText.AddStrings SPACE$(12)+"hBrush=CreateSolidBrush(CAST(COLORREF, "+objPtr+"->Color))"
      ELSEIF tstr="QCOMBOBOX" THEN
        objPtr=RTRIM$(FB_Objects(i).FBObjPtrName)
        FBCodeText.AddStrings SPACE$(8)+"CASE "+objPtr+"->hEdit"
        FBCodeText.AddStrings SPACE$(12)+"SetBKMode(hDC, 1)"
        FBCodeText.AddStrings SPACE$(12)+"SetTextColor(hDC, CAST(COLORREF, "+objPtr+"->Font.Color))"
        FBCodeText.AddStrings SPACE$(12)+"hBrush=CreateSolidBrush(CAST(COLORREF, "+objPtr+"->Color))"
      END IF
    NEXT i
    FBCodeText.AddStrings SPACE$(4)+"END SELECT"
  END IF
  FBCodeText.AddStrings SPACE$(4)+"RETURN CAST(LRESULT, hBrush)"
  FBCodeText.AddStrings "END FUNCTION"
END SUB

'-- ***************************************************************************************************
SUB FB_CtlColorStatic
  DEFSTR tstr, objPtr
  DEFINT i, Addem=False

  FBCodeText.AddStrings "","FUNCTION CheckStaticColor(wParam AS WPARAM, lParam AS LPARAM) AS LRESULT"
  FBCodeText.AddStrings "DIM AS HBRUSH hBrush=NULL"
  FOR i=1 TO ObjCount-1
    tstr=UCASE$(RTRIM$(FB_Objects(i).FBObjType))
    SELECT CASE tstr
    CASE "QLABEL","QTRACKBAR"
      Addem=True
      EXIT FOR
    END SELECT
  NEXT i
  IF Addem THEN
    FBCodeText.AddStrings "DIM AS HDC hDC=CAST(HDC, wParam)"
    FBCodeText.AddStrings "DIM AS HWND Handle=CAST(HWND, lParam)",""
    FBCodeText.AddStrings SPACE$(4)+"SELECT CASE Handle"
    FOR i=1 TO ObjCount-1
      tstr=UCASE$(RTRIM$(FB_Objects(i).FBObjType))
      IF (tstr="QLABEL") OR (tstr="QTRACKBAR")  THEN
        objPtr=RTRIM$(FB_Objects(i).FBObjPtrName)
        FBCodeText.AddStrings SPACE$(8)+"CASE "+objPtr+"->Handle"
        FBCodeText.AddStrings SPACE$(12)+"SetBKMode(hDC, 1)"
        FBCodeText.AddStrings SPACE$(12)+"SetTextColor(hDC, CAST(COLORREF, "+objPtr+"->Font.Color))"
        FBCodeText.AddStrings SPACE$(12)+"hBrush=CreateSolidBrush(CAST(COLORREF, "+objPtr+"->Color))"
      END IF
    NEXT i
    FBCodeText.AddStrings SPACE$(4)+"END SELECT"
  END IF
  FBCodeText.AddStrings SPACE$(4)+"RETURN CAST(LRESULT, hBrush)"
  FBCodeText.AddStrings "END FUNCTION"
END SUB

'-- ***************************************************************************************************
SUB FB_CheckForListBox
  DEFSTR tstr, tok
  DEFINT i, Addem=False

  FBCodeText.AddStrings "","FUNCTION CheckListBoxColor(wParam AS WPARAM, lParam AS LPARAM) AS LRESULT"
  FBCodeText.AddStrings "DIM AS HBRUSH hBrush=NULL"
  FOR i=1 TO ObjCount-1
    tstr=UCASE$(RTRIM$(FB_Objects(i).FBObjType))
    SELECT CASE tstr
    CASE "QLISTBOX", "QFILELISTBOX", "QCOMBOBOX"
      Addem=True
      EXIT FOR
    END SELECT
  NEXT i
  IF Addem THEN
    FBCodeText.AddStrings SPACE$(4)+"SELECT CASE lParam"
    FOR i=1 TO ObjCount-1
      tstr=UCASE$(RTRIM$(FB_Objects(i).FBObjType))
      SELECT CASE tstr
      CASE "QLISTBOX", "QFILELISTBOX"
        tok=TRIM$(FB_Objects(i).FBObjPtrName)
        FBCodeText.AddStrings SPACE$(8)+"CASE "+tok+"->Handle"
        FBCodeText.AddStrings SPACE$(12)+"DIM AS HDC hDC=CAST(HDC, wParam)"
        FBCodeText.AddStrings SPACE$(12)+"DIM AS HGDIOBJ Original=SelectObject(hDC, GetStockObject(DC_BRUSH))"
        FBCodeText.AddStrings SPACE$(12)+"hBrush=CreateSolidBrush(CAST(COLORREF, "+tok+"->Color))"
        FBCodeText.AddStrings SPACE$(12)+"SetBkMode(hDC, 1)                          ' Transparent"
        FBCodeText.AddStrings SPACE$(12)+"SetTextColor(hDC, CAST(COLORREF,"+tok+"->Font.color))"
      CASE "QCOMBOBOX"
        tok=TRIM$(FB_Objects(i).FBObjPtrName)
        FBCodeText.AddStrings SPACE$(8)+"CASE "+tok+"->hList"
        FBCodeText.AddStrings SPACE$(12)+"DIM AS HDC hDC=CAST(HDC, wParam)"
        FBCodeText.AddStrings SPACE$(12)+"DIM AS HGDIOBJ Original=SelectObject(hDC, GetStockObject(DC_BRUSH))"
        FBCodeText.AddStrings SPACE$(12)+"hBrush=CreateSolidBrush(CAST(COLORREF, "+tok+"->Color))"
        FBCodeText.AddStrings SPACE$(12)+"SetBkMode(hDC, 1)                          ' Transparent"
        FBCodeText.AddStrings SPACE$(12)+"SetTextColor(hDC, CAST(COLORREF,"+tok+"->Font.color))"
      END SELECT
    NEXT i
    FBCodeText.AddStrings SPACE$(4)+"END SELECT"
  END IF
  FBCodeText.AddStrings SPACE$(4)+"RETURN CAST(LRESULT, hBrush)"
  FBCodeText.AddStrings "END FUNCTION"
END SUB

'-- ***************************************************************************************************
' Currently not used
SUB FB_FillWmDrawItem
  FBCodeText.AddStrings "","SUB CheckWmDrawItem(wParam AS WPARAM, lParam AS LPARAM)"
  FBCodeText.AddStrings "END SUB"
END SUB

'-- ***************************************************************************************************
SUB FB_FillPopup
  DEFINT i
  DEFSTR tstr

  FBCodeText.AddStrings "","' Hook into the Popup menus for all of your components here"
  FBCodeText.AddStrings "SUB CheckWmContextMenu(hWnd AS HWND, wMsg AS UINT, wParam AS WPARAM, lParam AS LPARAM)"
  '    FBCodeText.AddStrings "' DIM AS UINT flags=TPM_RETURNCMD OR TPM_RIGHTBUTTON OR TPM_NOANIMATION"
  '    FBCodeText.AddStrings "' DIM AS integer Idx",""
  '    FBCodeText.AddStrings "' "+SPACE$(4)+"SELECT CASE wParam"
  '    FBCodeText.AddStrings "' "+SPACE$(8)+"CASE Obj->Handle                                           ' Check for objects with a popup menu"
  '    FBCodeText.AddStrings "' "+SPACE$(12)+"IF (Obj->PopupMenu>0) AND (Obj->OnPopUp>0) THEN"
  '    FBCodeText.AddStrings "' "+SPACE$(16)+"Idx=TrackPopupMenuEx(Obj->PopupMenu, flags, LOWORD(lParam), HIWORD(lParam), Obj->Handle, 0)"
  '    FBCodeText.AddStrings "' "+SPACE$(16)+"Obj->OnPopUp(Idx)                                 ' OnPopUp is the event handler"
  '    FBCodeText.AddStrings "' "+SPACE$(12)+"END IF"
  '    FBCodeText.AddStrings "' "+SPACE$(4)+"END SELECT"
  FBCodeText.AddStrings "END SUB"
END SUB

'-- ***************************************************************************************************
SUB FB_FillSocketEvents
  DEFINT i, Addem=False
  DEFSTR tstr

  FBCodeText.AddStrings "","SUB CheckSocketEvent(hWnd AS HWND, wMsg AS UINT, wParam AS WPARAM, lParam AS LPARAM)"
  FOR i=1 TO ObjCount-1
    tstr=UCASE$(RTRIM$(FB_Objects(i).FBObjType))
    IF tstr="QSOCKET" THEN
      Addem=True
      EXIT FOR
    END IF
  NEXT i
  IF AddEm THEN
    FBCodeText.AddStrings "' Server: Only ONE message of interest on the server master socket - FD_ACCEPT"
    FBCodeText.AddStrings "' Client: Only ONE message of interest FD_CLOSE, remainder of messages optional"
    FBCodeText.AddStrings "' NB The wParam is the socket descriptor (handle)"
    FBCodeText.AddStrings SPACE$(4)+"IF HIWORD(lParam)=0 THEN"
    FBCodeText.AddStrings SPACE$(8)+"SELECT CASE lParam"
    FBCodeText.AddStrings SPACE$(12)+"CASE FD_ACCEPT"
    FBCodeText.AddStrings SPACE$(16)+"lpSocket1->ConnPending=True                ' Remote connection request"
    FBCodeText.AddStrings SPACE$(12)+"CASE FD_CONNECT                                '|"
    FBCodeText.AddStrings SPACE$(12)+"CASE FD_READ                                   '| Client socket asynch mode,..."
    FBCodeText.AddStrings SPACE$(12)+"CASE FD_WRITE                                  '| ...add your dispatch code here"
    FBCodeText.AddStrings SPACE$(12)+"CASE FD_CLOSE                                  '|"
    FBCodeText.AddStrings SPACE$(16)+"lpSocket1->DiscPending=wParam              ' Remote disconnect notification"
    FBCodeText.AddStrings SPACE$(8)+"END SELECT"
    FBCodeText.AddStrings SPACE$(4)+"ELSE"
    FBCodeText.AddStrings SPACE$(8)+"lpSocket1->SockError=WSAGetLastError()"
    FBCodeText.AddStrings SPACE$(4)+"END IF"
  END IF
  FBCodeText.AddStrings "END SUB"
END SUB

'-- ***************************************************************************************************
SUB FB_AddMainFormCode
  DEFSTR tok

  tok=RTRIM$(FB_Objects(0).FBObjPtrName)
  FBCodeText.AddStrings SPACE$(4)+tok+"->Center                         ' You may wish to delete this line",""
  FBCodeText.AddStrings SPACE$(4)+"IF "+tok+"->OnShow>0 THEN "+tok+"->OnShow("+tok+")",""
  FBCodeText.AddStrings SPACE$(4)+"Result = "+tok+"->ShowModal             ' Show form & call default message handler",""
  FBCodeText.AddStrings SPACE$(4)+"' You may want to change the above line to "+tok+"->Show, and then provide"
  FBCodeText.AddStrings SPACE$(4)+"' your own function that, amongst other things, handles all window messages."
END SUB

'-- ***************************************************************************************************
SUB xFB_AddMainFormCode
  DEFSTR tok

  tok=RTRIM$(FB_Objects(0).FBObjPtrName)
  FBCodeText.AddStrings SPACE$(4)+"ConfigureComponents()",""
  FBCodeText.AddStrings SPACE$(4)+"' Load the Main form"
  FBCodeText.AddStrings SPACE$(4)+tok+"->Parent = 0"
  FBCodeText.AddStrings SPACE$(4)+tok+"->Handle = CreateWindowEx(0, "+QU+"RQClass"+QU+", "+tok+"->Caption, _"
  FBCodeText.AddStrings SPACE$(20)+"WS_OVERLAPPEDWINDOW, _"
  FBCodeText.AddStrings SPACE$(20)+tok+"->Left, "+tok+"->Top, "+tok+"->Width, "+tok+"->Height, _"
  FBCodeText.AddStrings SPACE$(20)+"0, 0, hInst, 0)"
  FBCodeText.AddStrings SPACE$(4)+"Application.hMainForm = "+tok+"->Handle",""
  FBCodeText.AddStrings SPACE$(4)+tok+"->Center                ' You may wish to delete this line",""
  FBCodeText.AddStrings SPACE$(4)+"' Load remainder of components"
  FBCodeText.AddStrings SPACE$(4)+"LoadComponents()",""
  FBCodeText.AddStrings SPACE$(4)+"ShowWindow("+tok+"->Handle, iCmdShow)"
  FBCodeText.AddStrings SPACE$(4)+"IF "+tok+"->OnShow>0 THEN "+tok+"->OnShow("+tok+")"
END SUB

'-- ***************************************************************************************************
SUB FB_FillFooter
  DIM tList AS QStringList
  DEFINT i
  DEFSTR tstr, FormPtr

  tList.Clear
  HelpRef.Position=0
  FOR i=1 TO HelpRef.LineCount
    tstr=HelpRef.ReadLine
    IF FIELD$(tstr," ",1)="#9" THEN EXIT FOR                    ' Find the FB Footer section
  NEXT i
  FOR i=i+1 TO HelpRef.LineCount                                  ' Fill the temporary stringlist
    tstr=HelpRef.ReadLine-CHR$(13)-CHR$(10)
    IF LEFT$(tstr,1)="#" THEN EXIT FOR                          ' End of section text
    tList.AddItems tstr
  NEXT i

  FormPtr=RTRIM$(FB_Objects(0).FBObjPtrName)
  i=0
  DO
    tstr=tList.Item(i)
    IF INSTR(tstr,"###")>0 THEN
      SELECT CASE LEFT$(tstr,13)
      CASE "' ### MarkerA": FB_KillTimerCode
      CASE "' ### MarkerB": FB_SysCheckHints
      CASE "' ### MarkerC"
        FB_FillTimerEvents                              '| Add the hooks code for ...
        FB_FillCmdEvents                                '| ...these main form messages
        FB_FillNotifyEvents                             '|
        FB_FillPaintEvents                              '|
        FB_CtlColorBtn                                  '| BUTTON types have to be OWNERDRAWN
        FB_CtlColorStatic                               '|
        FB_CtlColorEdit                                 '|
        FB_CheckForListBox                              '|
        FB_FillScrollItems                              '|
        FB_FillSocketEvents                             '|
        FB_FillPopup                                    '| Place to hook any popup menus
        FB_FillHitTestEvents                            '|
        FB_FillWmDrawItem                               '|
      CASE "' ### MarkerD":                               ' Spare ATT
      CASE "' ### MarkerE": FB_AddMainFormCode
      END SELECT
    ELSE
      IF INSTR(tstr,"$$ptr$$")>0 THEN tstr=REPLACESUBSTR$(tstr,"$$ptr$$",FormPtr)
      FBCodeText.AddStrings tstr
    END IF
    INC i
  LOOP UNTIL i >= tList.ItemCount
  tList.Clear
END SUB

'-- ***************************************************************************************************
SUB FB_AddUserStubs
  DEFINT i, j, idx
  DEFSTR tstr, tok1, tok2
  DEFSTR MyFuncList=""

  FBCodeText.AddStrings "", "'-------------------------------------------------------------------------------"
  FBCodeText.AddStrings "' Code for the component events"
  FBCodeText.AddStrings "'-------------------------------------------------------------------------------"
  i=0
  DO
    j=FB_Objects(i).FBLineNum+1
    FOR idx=j TO FB_InputList.ItemCount-1
      tstr=LTRIM$(RTRIM$(FB_InputList.Item(idx)))
      IF LEFT$(tstr,1)="#" THEN EXIT FOR
      IF LEFT$(tstr,2)="On" THEN
        tok1=FIELD$(tstr,"|",2)                                 ' User defined sub event
        tok2=FIELD$(tstr,"|",3)                                 ' Sub event parameters
        IF tok1<>"" THEN                                        ' A defined sub event?
          IF INSTR(MyFuncList,tok1)=0 THEN
            MyFuncList=MyFuncList+","+tok1                  ' Add to global list
            tok1="SUB "+tok1
            IF tok2="" THEN
              tok1=tok1+"(Sender AS "+RTRIM$(FB_Objects(i).FBObjType)+")"
            ELSE
              IF INSTR(tok2,"QRECT")>0 THEN tok2=FixQRect(tok2)           ' Replace RQ QRECT reference
              tok1=tok1+LEFT$(tok2,LEN(tok2)-1)
              tok1=tok1+", Sender AS "+RTRIM$(FB_Objects(i).FBObjType)+")"
            END IF
            FBCodeText.AddStrings tok1,"END SUB",""
          END IF
        END IF
      END IF
    NEXT idx
    INC i
  LOOP UNTIL i >= ObjCount
END SUB

'-- ***************************************************************************************************
SUB FB_GetFormData
  DEFINT i, j
  DEFSTR tstr, tok
  DIM NoSupport AS QStringList

  FB_InputList.Clear
  FOR i=0 TO ObjectIndex-1
    FB_InputList.AddItems "#"+STR$(i+1)
    tstr=AddedObjectList(i)
    FOR j=1 TO TALLY(tstr,"~")+1
      tok=LEFT$(FIELD$(tstr,"~",j),128)
      FB_InputList.AddItems tok
    NEXT j
  NEXT i

  NoSupport.Clear
  FOR i=0 TO FB_InputList.ItemCount-1
    tstr=FB_InputList.Item(i)
    IF LEFT$(tstr,1)="#" THEN
      INC i
      tstr=FB_InputList.Item(i)
      IF FB_HasSupport(FIELD$(tstr,"|",2)) THEN
        FB_Objects(ObjCount).FBLineNum=i
        FB_Objects(ObjCount).FBObjID=VAL(FIELD$(tstr,"|",1))
        FB_Objects(ObjCount).FBObjType=FIELD$(tstr,"|",2)
        FB_Objects(ObjCount).FBObjName=FIELD$(tstr,"|",5)
        FB_Objects(ObjCount).FBObjPtrName="lp"+FIELD$(tstr,"|",5)
        FB_Objects(ObjCount).FBObjHandle=VAL(FIELD$(tstr,"|",3))
        FB_Objects(ObjCount).FBObjParent=VAL(FIELD$(tstr,"|",6))
        FB_Objects(ObjCount).FBChildCount=0
        INC ObjCount
      ELSE
        NoSupport.AddItems FIELD$(tstr,"|",2)
      END IF
    END IF
  NEXT i
  IF NoSupport.ItemCount>0 THEN
    tstr="Sorry, no support for:"+CRLF+CRLF
    FOR i=0 TO NoSupport.ItemCount-1
      tstr=tstr+NoSupport.Item(i)+CRLF
    NEXT i
    tstr=tstr+CRLF+"Code for the remainder of the"+CRLF+"components will be created!"
    MessageBox(tstr,"RapidFRM limitation",&h40)
  END IF
END SUB

'-- ***************************************************************************************************
SUB FB_SaveAndExit
  DEFSTR tstr, outstr
  DEFINT i

  FBCodeText.SelectAll
  FBCodeText.CopyToClipBoard
  FBCodeText.SelLength=0                                           ' De-select text
  DoEvents
  ClipBoard.Open
  tstr=ClipBoard.text
  ClipBoard.Clear
  ClipBoard.Text=tstr
  ClipBoard.Close
  ErrorCondition=False: ObjectIndex=ComponentCount                ' 2 Conditions set to exit immediately
  ProgramEnd
END SUB

'-- ***************************************************************************************************
' RQ format source file as a template for FB
SUB SaveTemplate
  DIM PM AS integer
  DIM FName AS string
  DIM SaveDialog AS QSAVEDIALOG

  PM=ProjectMode: ProjectMode=-1      ' NO header or footer wanted
  BuildFormCode                       ' RQ template code
  ProjectMode=PM
  SaveDialog.InitialDir=CURDIR$
  SaveDialog.Filter="FreeBASIC template file (*.tpl)|*.tpl|You choose (*.*)|*.*"
  IF SaveDialog.Execute THEN
    FName=SaveDialog.FileName
    IF INSTR(FName,".")=0 THEN FName=FName+".tpl"
    CodeText.SaveToFile(FName)
  ELSE
    MessageBox("No file saved!","Save Template File",&h10)
  END IF
END SUB

'-- ***************************************************************************************************
SUB BuildFBCode
  ScanTimer.Enabled=False                  ' Stop everything else that's going on
  ClipBoard.Clear                     ' Signal to IDE?

  FBCodeText.Clear                     ' Start with a clean slate
  ObjCount=0                          ' ditto
  FB_GetFormData                      ' Load the global FB_InputList of form design
  FB_FillHeader                       ' Header includes (varies with components)
  FB_AddGlobals                       ' Global component structure & pointer creation
  FB_AddFwdDeclares                   ' Component event subs
  FB_ConfigureObjects                 ' Code to initialise component global structures
  FB_CreateObjects                    ' System load of the components
  FB_FillFooter                       ' Main Form load, component load, msg loop etc
  FB_AddUserStubs                     ' Dummy subs for component event code

  ScanTimer.Enabled=True
END SUB


'-- ***************************************************************************************************
SUB  SaveAsOnClick1        '' SaveAs item clicked

  SaveDialog.InitialDir=StartPath$
  SaveDialog.Filter ="*.bas|*.bas|*.rqb|*.rqb|_
  *.txt|*.txt|*.*|*.*"
  SaveDialog.FilterIndex = 1    '' Use "All Files" as our default
  SaveDialog.FileName=SrcFileName '+".bas"
  pntpos=instr(SaveDialog.Filter, ".")
  DelimPos=instr(SaveDialog.Filter, "|")
  xTFilter$=left$(SaveDialog.Filter, DelimPos-1) -"."-"*"
  'call  AddClrString ("4212:xTFilter$="+(xTFilter$), cldr, LogEdit)

  IF SaveDialog.Execute THEN
    'call  AddClrString ("4209:SaveDialog.Filter="+(SaveDialog.Filter), clred, LogEdit)
    'call  AddClrString ("4223:SaveDialog.FileName="+str$(SaveDialog.FileName), clred, LogEdit)
    if instr(SaveDialog.FileName,".")=0 then
      SaveDialog.FileName=SaveDialog.FileName+"."+xTFilter$
    end if

    Showmessage SaveDialog.FileName

    IF FileExists(SaveDialog.FileName) <> FALSE THEN
      IF MessageBox("Replace file"+chr$(10)+SaveDialog.FileName +" ?", "Warning!", 1) = 1 THEN
      else
        exit sub
      END IF
    END IF
    SrcFileName=SaveDialog.FileName
    'StatusPanel5.Caption=SrcFileName
    ' если файл из списка окон, то при переименовании меняем название в списке
    'if EditFlg=0 then WindMnu(WindowsIndex).caption=str$(WindowsIndex)+ chr$(160)+SrcFileName

    'if SaveString(SrcEdit.text ,SrcFileName  )< 1 then
    'showmessage ("Can't save source into "+SrcFileName)
    'exit sub
    'end if
    'SrcEdit.Modified=0
  ELSE
  END IF

END SUB



'-----------------------------------------------------------------------------------
'----------------------------- RapidQ Information ----------------------------------
'-----------------------------------------------------------------------------------
'
' Format of FIRST section ("~" separated) of each AddedObjectList() entry :-
' <Object ID>|<Object descriptor>|<Object Handle>|<Internal name>|***<External name>|<Parent handle>~
' *** If standalone mode internal name else external name derived from users source code
'
' eg Object ID order of components in file "Component.data"
' "0|QFORM|123456|Form1|MyForm|654321~Left = 20|Top = 20|Width....etc"
' "4|QBUTTON|234567|Butn1|ExitBtn|765432~.......etc"
'-----------------------------------------------------------------------------------

brem 0
=============== отслеживать перемещение формы за caption
private
procedure WMNCRBUTTONDOWN(var msg: TMessage); message WM_NCRBUTTONDOWN;
procedure WMNCLBUTTONDOWN(var msg: TMessage); message WM_NCLBUTTONDOWN;
procedure WMNCLBUTTONDBLCLK(var msg: TMessage); message WM_NCLBUTTONDBLCLK;
end;



implementation


procedure TForm1.WMNCRBUTTONDOWN(var msg: TMessage);
begin
if msg.wParam = HTCAPTION then Caption := 'Right Click!';
// Message.Result := 0; {to ignore the message}
inherited;
end;

procedure TForm1.WMNCLBUTTONDOWN(var msg: TMessage);
begin
if msg.wParam = HTCAPTION then Caption := 'Left Click!';
// Message.Result := 0; {to ignore the message}
inherited;
end;

procedure TForm1.WMNCLBUTTONDBLCLK(var msg: TMessage);
begin
if msg.wParam = HTCAPTION then Caption := 'Double Click!';
// Message.Result := 0; {to ignore the message}
inherited;
end;
=================
erem

'*****************************************
Sub HideFormsBtnOnClick
  defint i

  'call  AddClrString ("7090:i="+str$(i), clred, LogEdit)
  if HideFormsBtn.caption="Hide Forms" then
    FOR i=0 TO MAX_FORMS
      'Forms(i).visible=0
      SetParent(Forms(i).Handle, FormsPanel.Handle)
    next
    HideFormsBtn.caption="Show Forms"
  else
    FOR i=0 TO MAX_FORMS
      'Forms(i).visible=1
      SetParent(Forms(i).Handle, DesignPan.Handle) ' DesignPan as parent for Forms(i)
    next
    HideFormsBtn.caption="Hide Forms"
  end if


End Sub
'*****************************************
Sub GlobalGridselectcell(Col&, Row&, CanSelect%, Sender as QStringgrid)
  with sender

    RichEdit1.text=.cell(Col&, Row&)
  end with
End Sub
'*****************************************
Sub GlobalGridondrawcell (Col&, Row&, State%, Rect AS QRect, Sender as QStringgrid)
  with Sender

    if instr(.cell(Col&, Row&),"||")>0 then 'and instr(.cell(Col&, Row&),"search")>0

      .FillRect(Rect.Left, Rect.Top, Rect.Left+.ColWidths(Col&), Rect.Top+.RowHeights(Row&), &HFFFFBE)
      .TextOut(Rect.Left+2, Rect.Top+2, .Cell(Col&, Row&), Clr2, -1)

    end if

    if (.cell(0, Row&))<>"" and Row&>0 then

      .FillRect(Rect.Left, Rect.Top, Rect.Left+.ColWidths(Col&), Rect.Top+.RowHeights(Row&), &H812CFF)
      .TextOut(Rect.Left+2, Rect.Top+2, .Cell(Col&, Row&), Clr2, -1)

    end if


    if Col&=.col and Row&=.row then

      .FillRect(Rect.Left, Rect.Top, Rect.Left+.ColWidths(Col&), Rect.Top+.RowHeights(Row&), &H81EAFF)
      .TextOut(Rect.Left+2, Rect.Top+2, .Cell(Col&, Row&), Clr2, -1)
    end if
  end with


End Sub

'--- New  WinProc StringGrid ---------------
FUNCTION  StringGridWndProc (hWnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
  Result =  CallWindowProc(OldStringGridWndProc, hWnd, uMsg, wParam, lParam)

  SELECT CASE uMsg
  case WM_MOUSEWHEEL
    if wParam> 0 then
      RQCompGlobalGrid.row=RQCompGlobalGrid.row-1
    else
      RQCompGlobalGrid.row=RQCompGlobalGrid.row+1
    end if

  end select

END FUNCTION

'*****************************************
sub SetFIELD(Source$,delim$,fnum%,updField$)
  'call  AddClrString ("7772:Source$="+(Source$), clred, LogEdit)
  'call  AddClrString ("7775:updField$="+(updField$), clred, LogEdit)
  defint b,e,i

  b=instr(Source$,delim$)

  For i=1 to fnum%-2
    'call  AddClrString ("7780:fnum%="+str$(fnum%), clred, LogEdit)
    b=instr(b+1,Source$,delim$)
  next
  e=instr(b+1,Source$,delim$)
  'call  AddClrString ("7785:e="+str$(e), clred, LogEdit)
  'Source$ = REPLACE$("Hello", "Jwer", 1) '-- returns Jwero
  'A$ = INSERT$("hi", "Hello", 3) '-- returns Hehillo
  Source$ = DELETE$(Source$, b+1, e-b-1) '-- Result: Ho world
  Source$ = INSERT$( updField$,Source$, b+1) '-- returns Hehillo
  'call  AddClrString ("7790:Source$="+(Source$), clred, LogEdit)
  'print"Source$=";Source$

end sub


'!*****************************************
SUB SetAddedObjProp(parenthWnd AS long,Sender AS QPANEL, otype as string, oIdx as long,_
                    oWidth as long, oHeight as long, color as long, border as long,ChildeInPanelType as string)

  'SetAddedObjProp(parenthWnd AS long,BoxRich(RichIndex), "QRICHEDIT", @RichIndex, 100, 50,clo,1,"")

  call  AddClrString ("========= 3557:SetAddedObjProp parent parenthWnd="+str$(parenthWnd), subclr, LogEdit)
  DEFSTR tstr, token
  DIM tPoint AS PointAPI
  dim rect as qrect
  ScanTimer.Enabled=False
  'call  AddClrString ("3116:flParsed="+str$(flParsed), clred, LogEdit)

  With sender

    '!!!!sender.Parent=Forms(FormIndex) '!!! MUST set a valid parent first!

    '!========== try to find real parent ==========================================

    'call  AddClrString ("3593:ParenthWnd="+str$(ParenthWnd), cldp, LogEdit)


    for i=0 to ObjectCount-1

      if ObjectHandle(i)= ParenthWnd then ' нашли индекс компонента родителя
        'call  AddClrString ("3593:ObjectHandle("+str$(i)+")="+str$(ObjectHandle(i)), cldp, LogEdit)
        exit for

      end if

    next i

    'call  AddClrString ("3602:ObjectIndex="+str$(i), cldp, LogEdit)
    'call  AddClrString ("3605:ObjectType("+str$(i)+")="+(ObjectType(i) ), cldp, LogEdit)
    zzz$=ObjectType(i)
    'call  AddClrString ("2460:zzz$="+(zzz$), clred, LogEdit)
    'call  AddClrString ("3606:FormCount="+str$(FormCount), clred, LogEdit)

    Select case ucase$(zzz$) '      смотрим тип родителя ucase$(ObjectType(ObjectIndex))
    case "QFORM"

      for i=0 to FormCount-1
        'call  AddClrString ("2464:FormIndex="+str$(i), clred, LogEdit)

        'call  AddClrString ("2466:ParenthWnd="+str$(ParenthWnd), clb, LogEdit)
        'call  AddClrString ("2466:Forms("+str$(i)+").handle)="+str$(Forms(i).handle), clb, LogEdit)
        if Forms(i).handle=ParenthWnd then
          call  AddClrString ("3611:Forms("+str$(i)+"handle)="+str$(Forms(i).handle), clred, LogEdit)
          sender.Parent=Forms(i)
          exit for ' искомый родитель dpan(PanIndex) !!!!

        end if

      next i

    case "QPANEL"

      for i=0 to PanCount-1

        if dpan(i).handle=ParenthWnd then
          sender.Parent=dpan(i)
          exit for ' искомый родитель dpan(i) !!!!

        end if

      next i


    case "QTABCONTROL" ' TabCtrl(1)

      for i=0 to TabContCount-1 'TabContIndex

        if BoxTab(i).handle=ParenthWnd then
          sender.Parent=BoxTab(i)
          'result= "BoxTab_"+str$(i)
          exit for ' искомый родитель TabCtrl(i) !!!!

        end if

      next i


    case "QGROUPBOX"  ' GrpBoxCount

      for i=0 to GrpBoxCount-1

        if GrpBox(i).handle=ParenthWnd then
          sender.Parent=GrpBox(i)
          exit for ' искомый родитель GrpBox(i) !!!!

        end if

      next i

    case "QSCROLLBOX"
      for i=0 to ScrollBCount-1

        if ScrollB(i).handle=ParenthWnd then
          sender.Parent=ScrollB(i)
          exit for ' искомый родитель ScrollB(i) !!!!

        end if

      next i

    case else
      'showmessage ( "14639:ObjectType("+str$(i)+")="+(ObjectType(i)+" not found") )
      call  AddClrString ("14639:ObjectType("+str$(i)+")="+(ObjectType(i)), clred, LogEdit)

    end select


    'exit sub
    '!====================================================================

    'call  AddClrString ("3546:ObjectIndex="+str$(ObjectIndex), clred, LogEdit)
    ObjectType(ObjectIndex)=otype 'список типов "QEDIT"
    'call  AddClrString ("3548:otype="+(otype), clred, LogEdit)
    ObjTypeIndex(ObjectIndex)=oIdx 'список номер экземпляра конкретного типа QEDIT
    'call  AddClrString ("3550:oIdx="+str$(oIdx), clred, LogEdit)
    ObjectHandle(ObjectIndex)=sender.Handle ' список хэндлов

    if childName$<>"" then
      token=childName$
    else
    end if


    if flParsed=0 then ' свойства!!!  компонента, если он устанавливается с палитры

      .Width=oWidth
      .Height=oHeight                                      ' ...to the defaults of QEdit
      .Color=(Hex$(color)) '&h00ffff
      'call  AddClrString ("3140:Hex$("+str$(color)+")="+(Hex$(color)), clred, LogEdit)
      '.BevelOuter=0'bvNone'2
      '.Alignment=taLeftJustify
      '.BevelWidth=0
      '.BevelInner=0
      '.BorderStyle=0'border
      '.BevelWidth=0

      token=otype+STR$(oIdx)-"Q"
      'call  AddClrString ("3603:token="+(token), clred, LogEdit)

      .Caption=token
      ObjectName(ObjectIndex)=token ' список имен объектов

      ' ПОЗИЦИЯ!!!  компонента, если он устанавливается с палитры
      tPoint.x=Screen.MouseX: tPoint.y=Screen.MouseY
      ScreenToClient(parenthWnd,tPoint)
      .Left=tPoint.x

      if otype="QSPLITTER" then
        .Top=0'tPoint.y
      else
        .Top=tPoint.y
      end if

    else ' берем свойства из таблицы PropertyGrid
      call  AddClrString ("3131:SetAddedObjProp call ReDrawComponentByField=", clred, LogEdit)
      ReDrawComponentByField
      'call  AddClrString ("3286:.Width="+str$(.Width), clred, LogEdit)
      'call  AddClrString ("3288:.Height="+str$(.Height), clred, LogEdit)


    end if

    '!!! устанавливаем каретку по полученным координатам объекта
    HideCarets                                                  ' If visible
    SetWindowPos(.Handle, 0, .Left, .Top, .Width, .Height, SW_FLAGS)
    GetWindowRect(.Handle,rect)
    ShowCarets(rect)

    if flParsed=0 then
      'call  AddClrString ("3635:flParsed="+str$(flParsed), clred, LogEdit)
      '!!! image1 as qimage  parent=form as qform
      token=token +" as "+ObjectType(ObjectIndex)+" parent="+_
      ObjectName(ObjParentIdx(ObjectIndex))+" as "+ ObjectType(ObjParentIdx(ObjectIndex))

      'call  AddClrString ("2465:token222="+(token), &H00CA00, LogEdit)

      SaveNewObjDataGrid(parenthWnd, token, ObjectIndex,.Left, .Top, .Width, .Height,.Color) '!!! сохранение таблицы
      'cmboxObj.addItems token +"3751"

    else ' берем свойства из таблицы PropertyGrid
      'ReDrawComponentByField
      ''call  AddClrString ("3182:SetAddedObjProp call ReDrawComponentByField=", clb, LogEdit)


    end if


  end with
  ScanTimer.Enabled=True


END SUB

'!*****************************************
SUB SaveNewObjDataGrid(hWnd as long, token as string,ObjectIndex as long,oLeft  as long, oTop  as long, oWidth as long,oHeight as long,oColor as long)

  call  AddClrString ("-------- 3160:SaveNewObjDataGrid hWnd="+str$(hWnd), subclr, LogEdit)
  'call  AddClrString ("3161:token="+(token), clb, LogEdit)
  'call  AddClrString ("3780:oColor="+str$(oColor), clred, LogEdit)

  'call  AddClrString ("3769:ObjectName("+str$(ObjectIndex)+")="+(ObjectName(ObjectIndex)), cldg, LogEdit)
  if ObjectName(ObjectIndex)="" then ObjectName(ObjectIndex)=token
  'call  AddClrString ("3769:ObjectName("+str$(ObjectIndex)+")="+(ObjectName(ObjectIndex)), cldg, LogEdit)

  ObjNameGrid.Cell(0,1)=ObjectName(ObjectIndex)
  ObjNameGrid.Cell(1,1)=ObjectType(ObjectIndex)

  PropertyGrid.cell(0,1)=ObjNameGrid.Cell(0,1)
  PropertyGrid.cell(1,1)=ObjNameGrid.Cell(1,1)

  cmboxObj.addItems token '+" 3783"
  'call  AddClrString ("3271:token="+(token), clb, LogEdit)
  cmboxObj.ItemIndex=ObjectIndex
  'cmboxObjOnChange

  '!!!  заменяем на сохранение свойств формы  в таблицу и таблицы в файл таблицы  <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

  '1 заполняем таблицу свойствами по умолчанию!!!
  datafn$=StartDir+"data\"+ObjectType(ObjectIndex)+".data"
  'call  AddClrString ("14290:datafn$="+(datafn$), 0, LogEdit)

  PropertyGrid.RowCount=50

  for ri=1 to PropertyGrid.RowCount-1
    for cj=0 to PropertyGrid.ColCount-1
      PropertyGrid.Cell(cj,ri)=""
    next
  next

  for ri=0 to DefaultPropertyGrid.RowCount-1
    for cj=0 to DefaultPropertyGrid.ColCount-1
      DefaultPropertyGrid.Cell(cj,ri)=""
    next
  next

  DefaultPropertyGrid.RowCount=1
  'DefaultPropertyGrid.LoadFromFile(datafn$,3,0,1000)
  DefaultPropertyGrid.LoadFromFile(datafn$,0,0,1000)

  PropertyGrid.RowCount= DefaultPropertyGrid.RowCount+1
  'call  AddClrString ("14639:DefaultPropertyGrid.RowCount="+str$(DefaultPropertyGrid.RowCount), clred, LogEdit)
  'call  AddClrString ("14639:PropertyGrid.RowCount="+str$(PropertyGrid.RowCount), clred, LogEdit)

  evRow=1
  prRow=1

  for ri=0 to EventGrid.RowCount-1
    for cj=0 to EventGrid.ColCount-1
      EventGrid.Cell(cj,ri)=""
    next
  next


  for i=1 to PropertyGrid.RowCount-1

    'if lcase$(left$(DefaultPropertyGrid.cell(0,i-1),2))="on" then
    'EventGrid.cell(0,evRow)=DefaultPropertyGrid.cell(0,i-1)
    'inc evRow
    'if EventGrid.RowCount<evRow then EventGrid.RowCount=evRow
    'else
    PropertyGrid.cell(0,i)=DefaultPropertyGrid.cell(0,i-1) ' невидимая таблица для DefaultProperty
    PropertyGrid.cell(1,i)=DefaultPropertyGrid.cell(2,i-1)
    PropertyGrid.cell (4,i)=DefaultPropertyGrid.cell (1,i-1)

    'inc prRow
    'end if



  next i

  evRow=1

  for i=1 to PropertyGrid.RowCount-1
    'call  AddClrString ("14657:lcase$("+str$(i)+")="+(lcase$(left$(DefaultPropertyGrid.cell(0,i-1),2))), clred, LogEdit)

    'if lcase$(left$(DefaultPropertyGrid.cell(0,i-1),2))="on" then
    'EventGrid.cell(0,evRow)=DefaultPropertyGrid.cell(0,i-3)
    'inc evRow
    'else
    'PropertyGrid.cell(3,i)=str$(i) ' номер строки
    'PropertyGrid.cell(1,i)=DefaultPropertyGrid.cell(2,i-1)
    'end if
  next i




  parent$=WhichParent(hWnd)
  'call  AddClrString ("3016:parent$="+(parent$), clm, LogEdit)
  'call  AddClrString ("3016:parent hWnd="+str$(hWnd), clm, LogEdit)

  '!!! заполняем таблицу свойствами компонента
  PropertyFieldUpdate("Caption",token)                          ' ..Width & Height defaults
  PropertyFieldUpdate("Parent",(WhichParent(hWnd)))               '
  PropertyFieldUpdate("Handle",str$(ObjectHandle(ObjectIndex)))               '
  PropertyFieldUpdate("Left", str$(oLeft))
  PropertyFieldUpdate("Top", str$(oTop))
  PropertyFieldUpdate("Width", str$(oWidth))
  PropertyFieldUpdate("Height", str$(oHeight))
  'PropertyFieldUpdate("Color", HEX$(oColor))
  PropertyFieldUpdate("Text", token)


  PropertyValueUpdate ' update cont alias to value

  '!!! сохраняем таблицу
  if projectDir$="" then ' создаем новый проект
    'projectDir$=StartDir+projectpath$+"Newproject "+time$-":"
    projectDir$=projectpath$+"Newproject "+time$-":"
    if direxists(projectDir$)=0 then
      mkdir projectDir$
    end if
  end if

  GridFileName$=projectDir$+"\"+trim$(field$(token," ",1))+".dat"
  call  AddClrString ("3396 :SetObjProp Сохраняем в GridFileName$="+(GridFileName$), cldr, LogEdit)
  PropertyGrid.SaveToFile(GridFileName$,0,0,PropertyGrid.RowCount)


END SUB

'!*****************************************


'*****************************************
Function GetQParent (ParenthWnd  AS long) as string
  '!========== try to find real parent ==========================================

  call  AddClrString ("7391:GetQParent ParenthWnd="+str$(ParenthWnd), cldp, LogEdit)


  for i=0 to ObjectCount-1

    if ObjectHandle(i)= ParenthWnd then ' нашли индекс компонента родителя
      call  AddClrString ("7397:ObjectHandle("+str$(i)+")="+str$(ObjectHandle(i)), cldp, LogEdit)
      exit for

    end if

  next i

  'call  AddClrString ("7404:ObjectIndex="+str$(i), cldp, LogEdit)
  'call  AddClrString ("7405:ObjectType("+str$(i)+")="+(ObjectType(i) ), cldp, LogEdit)
  zzz$=ObjectType(i)
  'call  AddClrString ("7407:zzz$="+(zzz$), clred, LogEdit)
  'call  AddClrString ("7409:FormCount="+str$(FormCount), clred, LogEdit)

  Select case ucase$(zzz$) ' смотрим тип родителя ucase$(ObjectType(ObjectIndex))
  case "QFORM"

    for i=0 to FormCount-1
      'call  AddClrString ("2464:FormIndex="+str$(i), clred, LogEdit)

      'call  AddClrString ("2466:ParenthWnd="+str$(ParenthWnd), clb, LogEdit)
      'call  AddClrString ("2466:Forms("+str$(i)+").handle)="+str$(Forms(i).handle), clb, LogEdit)
      if Forms(i).handle=ParenthWnd then
        call  AddClrString ("3611:Forms("+str$(i)+"handle)="+str$(Forms(i).handle), clred, LogEdit)
        'sender.Parent=Forms(i)
        result= "forms_"+str$(i)
        exit for ' искомый родитель Forms(i) !!!!

      end if

    next i

  case "QPANEL"

    for i=0 to PanCount-1

      if dpan(i).handle=ParenthWnd then
        'sender.Parent=dpan(i)
        'call  AddClrString ("7464: dpan_"+str$(i)+")", clb, LogEdit)
        result= "dpan_"+str$(i)
        exit for ' искомый родитель dpan(i) !!!!

      end if

    next i


  case "QTABCONTROL" ' TabCtrl(1) BoxTab(TabContIndex)

    for i=0 to TabContCount-1

      if BoxTab(i).handle=ParenthWnd then
        'sender.Parent=BoxTab(i)
        result= "BoxTab_"+str$(i)

        exit for ' искомый родитель TabCtrl(i) !!!!

      end if

    next i


  case "QGROUPBOX"  ' GrpBoxCount

    for i=0 to GrpBoxCount-1

      if GrpBox(i).handle=ParenthWnd then
        'sender.Parent=GrpBox(i)
        result ="grpbox_"+str$(i)

        exit for ' искомый родитель GrpBox(i) !!!!

      end if

    next i

  case "QSCROLLBOX"
    for i=0 to ScrollBCount-1

      if ScrollB(i).handle=ParenthWnd then
        'sender.Parent=ScrollB(i)
        result ="scrollb_"+str$(i)
        exit for ' искомый родитель ScrollB(i) !!!!

      end if

    next i

  case else
    showmessage ( "7483:ObjectType("+str$(i)+")="+(ObjectType(i)+" not found") )

  end select


  'exit sub
  '!====================================================================




END FUNCTION

'*****************************************
Sub GetOpersList (~SrcD as Qrichedit,StringList1 as QStringList)

  ' заполняем масcив начальных и конечных позиций операторов для подсветки при перемещении по шагам.
  '-------- operators positions ----------------------
  ~SrcDLineCount=~SrcD.LineCount ' число строк
  DobOperCnt=2*GetCharNum(~SrcD.text,":") ' число разделителей операторов

  AllOper=~SrcDLineCount+DobOperCnt

  reDim ~Op(AllOper) as string
  redim ~OpPos(AllOper) as integer
  redim ~OpLen(AllOper) as integer

  ' позиции операторов для подсветки !!! ------------------------------
  call GetOperators1 (~Op() ,~OpPos(),~OpLen(), ~SrcD.text, @opercnt)

  for i=0 to opercnt-1
    StringList1.AddItems ~Op(i)
    ''call  AddClrString ((~Op(i)), cldb, LogEdit)
  next i

END SUB
'*****************************************
sub GetOperators1 (Oper$() as string,OperPos() as integer, OperLen() as integer, SrcTxt$ as string,NumOpers as long)
  'parse and return  operators in checked string SrcTxt$
  'operators - not quoted and not commented parts of line delimited by ":"
  'Oper$() - array of operators
  'OperPos() - operator's positions

  ch$=chr$(58)' ":"
  QTNum=0
  dim SrcList as QStringList
  bop=1: eop=1

  SrcList.text=SrcTxt$

  ' обрабока конкатенации строк подчеркиванием _
  'Gauge2.position=0
  oldi=0
  for i=0 to  SrcList.ItemCount-1
    if i>oldi+150 then
      oldi=i
      'Gauge2.position=i/(SrcList.ItemCount+1)*100
    end if
    doevents

    ReplaceComments (@SrcList.Item(i))
  next i

  SrcTxt$=SrcList.text
  SrcTxt$=replacesubStr$(SrcTxt$,ht," ") '!!!!!!!!!!!!!!!!!!!!!!!

  ssCnt=Tally(SrcTxt$,"_")
  pos_=0

  if instr(SrcTxt$, crlf)>0 then
    EOL$=cr
  elseif instr(SrcTxt$, cr)>0 then
    EOL$=cr
  elseif instr(SrcTxt$, lf)>0 then
    EOL$=lf
  else
    Showmessage("1098:No EOL found")
  end if

  fl_=0
  fl_dob=0

  chrsSum$=""

  k=0
  'Gauge2.position=0
  oldi=0

  lensrc=Len(SrcTxt$)

  for ~i=1 to lensrc 'Len(SrcTxt$)


    if ~i>oldi+150 then
      oldi=~i
      'Gauge2.position=~i/(lensrc+1)*100
    end if
    doevents
    chrs$=SrcTxt$[~i]
    asc1=asc(chrs$)
    chrsSum$=chrsSum$+chrs$
    'если следующий за _ символ не пробел или конец строки, то сбрасываем флаг конкатенации
    if  fl_=1 and chrs$<>cr and chrs$<>lf and chrs$<>" " then fl_=0

    if chrs$=qt and QTNum=0 then
      QTNum=1 'следующий char  находится после первого вхождения qt
    elseif chrs$=qt and QTNum=1 then
      QTNum=0 'следующий char находимся после второго вхождения qt
    elseif chrs$="_"  then
      if  fl_=0 then
        fl_=1 ' устанавливаем флаг конкатенации
        fl_dob=1
      end if

    elseif (chrs$=":" or chrs$=EOL$ ) and QTNum=0 and fl_=0 then
      eop=~i
      ~tmp$=RTrim$(mid$(SrcTxt$,bop,eop-bop)) 'trim$

      if trim$(~tmp$-cr-lf)<>"" and trim$(~tmp$-cr-lf)<>":"  and trim$(~tmp$)<>EOL$  then 'and fl_=0
        Oper$(k)=trim$(~tmp$-cr-lf)
        OperPos(k)=bop
        OperLen(k)=eop-bop

        If instr(Oper$(k),"_")>0 then 'разбираемся с конкатенациями
          ~tmp$=""
          ~tmp2$=""
          ssCnt=Tally(Oper$(k),"_")
          for i=1 to ssCnt+1
            ~tmp$=(field$(Oper$(k),"_",i))
            ~tmp1$=(field$(Oper$(k),"_",i+1))

            if trim$(~tmp1$)<>"" and right$(~tmp$,1)<>" " then ~tmp$=~tmp$+"_"
            ~tmp2$=~tmp2$+~tmp$
          next i
          Oper$(k)=trim$(~tmp2$)
        end if
        k ++
      end if
      if chrs$=EOL$ then
        bop=eop+2
      else
        bop=eop+1
      end if
    else
    end if
  next ~i
  eop=~i

  ~tmp$=trim$(mid$(SrcTxt$,bop,eop-bop))
  if trim$(~tmp$)<>"" then
    Oper$(k)=trim$(~tmp$)
    OperPos(k)=bop
  end if
  'Gauge2.position=0

  NumOpers=k
end sub '
'-- *********************************************************************'

'-- ************************************************************************'
sub cmpEditOnKeyUp (Key AS WORD, Shift AS INTEGER)
  call  AddClrString ("7906:Key="+str$(Key), clred, LogEdit)

  if  key=13  then

    if direxists(EditRCPath.text)=0 then
      EditRCPath.text=StartDir

    end if
    DZGini.write("CompPath",EditRCPath.text )
    call  AddClrString ("7914:EditRCPath.text="+(EditRCPath.text), clred, LogEdit)


  end if

end sub


'*****************************************
Sub PropertyGridOnKeyPress(Key AS BYTE)
  ' окончание редактирования поля, перерисовка контрола и сохранение таблицы
  'OldPv$=PropertyGrid.Cell(PropertyGrid.Col,PropertyGrid.Row) '!сохраняем предыдущее значение!!

  SELECT CASE Key
  CASE 27
    'PropertyGrid.Cell(PropertyGrid.Col,PropertyGrid.Row)=OldPv$ '!восстанавливаем предыдущее значение!!
    PropertyGrid.Cell(PropertyGrid.Col,PropertyGrid.Row)=OldPv$ '!восстанавливаем предыдущее значение!!
    call  AddClrString ("14687:OldPv$="+(OldPv$), clred, LogEdit)


  CASE VK_Enter
    'exit sub
    PropertyValueUpdate ' update cont alias to value
    '!!! сохраняем таблицу
    'GridFileName$=projectDir$+"\"+trim$(PropertyGrid.Cell(0,1))+".dat"
    GridFileName$=projectDir$+"\"+trim$(ObjectName(ObjectIndex))+".dat"

    call  AddClrString ("3476: keyPress GridFileName$="+(GridFileName$), clred, LogEdit)
    PropertyGrid.SaveToFile(GridFileName$,0,0,PropertyGrid.RowCount)


    '!!! чума какая-то! Мы просто поменяли одно свойство у объекта! Зачем все обновлять???
    'перерисовка контрола
    ReDrawComponentbyField

    'call  AddClrString ("2886:projectDir$="+(projectDir$), clred, LogEdit)

    if projectDir$="" then ' создаем новый проект
      'projectDir$=StartDir+projectpath$+"Newproject "+time$-":"
      projectDir$=projectpath$+"Newproject "+time$-":"
      'projectDir$=ExtractFileName(SrcFileName$)
      'projectDir$=FileNameNoExt(projectDir$)
      'projectDir$=projectpath$+projectDir$
      ''call  AddClrString ("962:projectDir$="+(projectDir$), clred, LogEdit)
      if direxists(projectDir$)=0 then
        mkdir projectDir$
      end if

    end if


  END SELECT


End Sub

'!******************************************
Sub PropertyGridOnDrawCell(Col% AS INTEGER, Row% AS INTEGER, State AS INTEGER, Rect AS QRECT)

  with PropertyGrid
    if PropertyGrid.col=Col% and PropertyGrid.Row=Row% then

      .FillRect(Rect.Left, Rect.Top, Rect.Left+.ColWidths(Col%), Rect.Top+.RowHeights(Row%),cla )
      .TextOut(Rect.Left+2, Rect.Top+2, .Cell(Col%, Row%), clb, -1)




    end if


    if (Row%>0 and Row%<DefaultPropertyGrid.RowCount-1 )  then '! and DefaultPropertyGrid.cell (1,Row%-1)="R"

      if DefaultPropertyGrid.cell (2,Row%-1)<> PropertyGrid.cell (1,Row%) then
        .FillRect(Rect.Left, Rect.Top, Rect.Left+.ColWidths(Col%), Rect.Top+.RowHeights(Row%),&HFFFFD2 )
        .TextOut(Rect.Left+2, Rect.Top+2, .Cell(Col%, Row%), clb, -1)


      end if

      if DefaultPropertyGrid.cell (1,Row%-1)="R" then

        'if PropertyGrid.col=1 and PropertyGrid.Row=Row% then
        .FillRect(Rect.Left, Rect.Top, Rect.Left+.ColWidths(Col%), Rect.Top+.RowHeights(Row%),clsilver )
        .TextOut(Rect.Left+2, Rect.Top+2, .Cell(Col%, Row%), clb, -1)

        'end if
      end if

      if DefaultPropertyGrid.cell (1,Row%-1)="W" then

        'if PropertyGrid.col=1 and PropertyGrid.Row=Row% then
        .FillRect(Rect.Left, Rect.Top, Rect.Left+.ColWidths(Col%), Rect.Top+.RowHeights(Row%),&HFFE5E7 )
        .TextOut(Rect.Left+2, Rect.Top+2, .Cell(Col%, Row%), clb, -1)

        'end if
      end if

      'PropertyGrid.cell (4,Row%)=DefaultPropertyGrid.cell (1,Row%-1)

    end if


  end with

End Sub

