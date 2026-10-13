$IFNDEF __RAPIDFRM_INC   ' IncManager: include guard
$DEFINE __RAPIDFRM_INC
'
' RapidFRM.inc
'
' 1. Moved the mouse Decl/Func etc out of mainline code to assist in debugging
'    using RapidDBG. (NO debugging is applied to "$INCLUDE..." files).
' 2. QCOLORDLG - Fix for QColorDialog
'    NB This is the original by D. Glodt with bug fixes and some tidies.
' 3. QTABCONTROL - Some extra functionality.
' 4. QOVALBTN major FUDGE to enable setting of caption (ONLY!).
' 5. RapidFRM component $Defines
'
'--------------------------------Additional API Declarations ---------------------------------------------
DECLARE FUNCTION GetActiveWindow LIB "user32" ALIAS "GetActiveWindow" () AS long
DECLARE FUNCTION WindowFromPoint LIB "user32" ALIAS "WindowFromPoint" (X AS long, Y AS long) AS long
DECLARE FUNCTION ScreenToClient LIB "user32" ALIAS "ScreenToClient" (hWnd AS long, lpPoint AS POINTAPI) AS long

DECLARE FUNCTION UpdateWindow LIB "user32" ALIAS "UpdateWindow" (hWnd AS long) AS integer
DECLARE FUNCTION InvalidateRect LIB "user32" ALIAS "InvalidateRect" (hWnd AS long, rect AS QRECT, _
bErase AS long) AS long
DECLARE FUNCTION SetBkColor LIB "gdi32" ALIAS "SetBkColor" (hdc AS long, crColor AS long) AS long
DECLARE FUNCTION DestroyWindow LIB "user32" ALIAS "DestroyWindow" (hWnd AS long) AS long


DECLARE FUNCTION SetWindowsHookEx LIB "user32" ALIAS "SetWindowsHookExA" (idHook AS long, lpFn AS long, _
hmod AS long, dwThreadId AS dword) AS long
DECLARE FUNCTION CallNextHookEx LIB "user32" ALIAS "CallNextHookEx" (hHook AS long, nCode AS long, _
wParam AS long, lParam AS long) AS long
DECLARE FUNCTION UnhookWindowsHookEx LIB "user32" ALIAS "UnhookWindowsHookEx" (hHook AS long) AS long
DECLARE FUNCTION GetCurrentThreadId LIB "kernel32" ALIAS "GetCurrentThreadId" () AS long

'---------------------------------------------------------------------------------------------------------
' 1. MouseHook Stuff
'   This code hooks into the main msg stream, and hence is not the fastest way
'   to monitor the mouse buttons. This is evident when moving/resizing components
'   rapidly, but works reasonably well.  Saves having an external dll, with no src code!
'
$DEFINE LMOUSE_BTN  1                                           ' Left Mouse Button
$DEFINE RMOUSE_BTN  2                                           ' Right Mouse Button
$DEFINE MMOUSE_BTN  4                                           ' Middle Mouse Button

$DEFINE WH_MOUSE    7                                           ' Hook mouse constant

DEFLNG hHook                                                    ' Var for hooking/unhooking mouse
DEFINT gMouseBtns                                               ' My (global) mouse btns

'*****************************************
' Here, ONLY interested in the mouse buttons (wParam)
' For info: MouseX & MouseY lParam->POINT struct (first part of a larger struct)
FUNCTION MouseProc(idHook AS long, wParam AS long, lParam AS long) AS long
IF idHook >= 0 THEN                                         ' If < 0 no processing required
	SELECT CASE (wParam AND &hf)
	CASE 1: gMouseBtns=LMOUSE_BTN                       ' Update the global mouse btns
	CASE 2: gMouseBtns=0
	CASE 4: gMouseBtns=RMOUSE_BTN
	CASE 5: gMouseBtns=0
	CASE 7: gMouseBtns=MMOUSE_BTN                       ' Don't use this but...
	CASE 8: gMouseBtns=0
	END SELECT
END IF
Result=CallNextHookEx(hHook, idHook, wParam, lParam)        ' Call the next hook
END FUNCTION

SUB HookTheMouse()
DEFLNG lpHookProc, ThreadID

lpHookProc=CODEPTR(MouseProc)                               ' Hook mouse button events
ThreadID=GetCurrentThreadId()
hHook=SetWindowsHookEx(WH_MOUSE,lpHookProc,0,ThreadID)
END SUB
'---------------------------------------------------------------------------------------------------------
' 2. Bug fix for QCOLORDIALOG component in RapidQ2.inc
' This is the original version by D. Glodt with bug fixes
'
'   Style cdNormal implemented - compact but expandable.
'   Dialog height fixed; dialog width dependant on style property
'   Position anywhere on-screen &/or relative to other objects
'       ONCE the Style has been set, using Left,Top,Width & Height.
'       Style defaults to cdNormal - compact mode but expandable.
'   Change dialog caption, if required.
'   Custom colours updated on exit (in case certain set of colours
'        required throughout one program)
'   Focus "captured" until dialog closed - ONE instance only!
'
$DEFINE cdNormal        0                                       ' Default compact style (expandable)
$DEFINE cdFullOpen      1                                       ' Custom color customisable style
$DEFINE cdNoFullOpen    2                                       ' Compact style, no custom color dialog

$DEFINE CC_HEIGHT       335                                     ' Height of ColorChooser window
$DEFINE CC_WIDTH_STD    225                                     ' Width of window when in compact style
$DEFINE CC_WIDTH_FULL   460                                     ' Width of window when in full style

TYPE QColorDlg EXTENDS QFORM
PUBLIC:
Width           AS long PROPERTY SET SetWidth               ' Force READ ONLY of this property
Height          AS long PROPERTY SET SetHeight              '            ditto
Style           AS long PROPERTY SET SetStyle               ' cdNormal, cdNoFullOpen, cdFullOpen
Left            AS long
Top             AS long
Caption         AS string                                   ' Configurable caption
Color           AS long                                     ' PreSet AND Resultant selected color
Colors(1 TO 16) AS long                                     ' Custom colors - User settable!
WindowHandle    AS long                                     ' Not used ATT

PRIVATE:
CC              AS CHOOSECOLOR

WITH QColorDlg
	
	' Set visual properties of dialog prior to displaying.
	FUNCTION HookProc(hWnd AS long, uMsg AS long, wParam AS long, lParam AS long) AS long
	DIM R AS QRECT
	DEFINT X, Y, W, H
	
	Result=0
	IF uMsg=WM_INITDIALOG THEN                              ' ALL initializing is done here 
		GetWindowRect(hWnd, R)
		W = R.Right-R.Left+1: H = R.Bottom-R.Top+1
		X=IIF((.Left < 0), (Screen.Width-W)\2, .Left)
		Y=IIF((.Top < 0),  (Screen.Height-H)\2, .Top)
		MoveWindow(hWnd, X, Y, W, H, 0) 
		IF .Caption <> "" THEN SetWindowText(hWnd, .Caption)
		Result=1
	END IF
	END FUNCTION
	
	SUB SetCustomColors
	DEFINT i
	
	FOR i=1 TO 16
		.Colors(i)=&hC0C0C0
	NEXT
	END SUB
	
	PUBLIC:
	FUNCTION Execute() AS integer
	Result = False                                          ' Default fail
	
	MEMSET(THIS.CC,0,SIZEOF(THIS.CC))                       ' Zero the structure
	.CC.lStructSize = SIZEOF(THIS.CC)
	.CC.hWndOwner = Application.Handle                      ' Keeps the focus on the chooser!!!!!
	.CC.hInstance = Application.hInstance
	.CC.lpCustColors = VARPTR(THIS.Colors(1))               ' Set the pointer to our custom color array
	.CC.lpfnHook = CODEPTR(THIS.HookProc)                   ' Set the initialisation hook
	.CC.RGBResult = .Color                                  ' Set initial selected color
	.CC.Flags = CC_RGBINIT OR CC_SHOWHELP OR CC_ENABLEHOOK  ' Some defaults
	SELECT CASE .Style                                      ' NB if style NOT set style=compact (but expandable!!)
	CASE cdNoFullOpen
		.CC.Flags = .CC.Flags OR CC_PREVENTFULLOPEN     ' Fixed size - compact
	CASE cdFullOpen
		.CC.Flags = .CC.Flags OR CC_FULLOPEN            ' Fixed size - expanded
	END SELECT
	IF ChooseColorDlg(THIS.CC) THEN                         ' Call the Color select Dialog
		.Color = .CC.RGBResult                              ' Update user selected color
		Result = True
	END IF
	END FUNCTION
	
	PROPERTY SET SetStyle (ccStyle AS long)
	.Style = ccStyle
	SELECT CASE ccStyle
	CASE cdNoFullOpen
		.Width = CC_WIDTH_STD
	CASE cdFullOpen
		.Width = CC_WIDTH_FULL
	CASE ELSE                                           ' cdNormal or invalid "dont care" value
		.Width = CC_WIDTH_STD                           ' Default: cdNormal, compact but expandable
	END SELECT
	END PROPERTY
	
	PROPERTY SET SetWidth (W AS long)
	' READONLY property
	END PROPERTY
	
	PROPERTY SET SetHeight (H AS long)
	' READONLY property
	END PROPERTY
	
	CONSTRUCTOR
	Style = cdNormal                                        ' Default to compact mode, but expandable
	Left = -1                                               ' Defaults center of screen
	Top = -1                                                ' ditto
	Width = CC_WIDTH_STD                                    ' Compact mode width
	Height = CC_HEIGHT                                      ' Default height (either mode)
	Color = 0                                               ' Default initial color
	Caption = ""                                            ' Default caption of chooser ("Color")
	BorderStyle = 0                                         ' Blank form
	WindowHandle = 0                                        ' Not used
	SetCustomColors                                         ' Default all to Lt. Grey
	END CONSTRUCTOR
END WITH
END TYPE

'---------------------------------------------------------------------------------------------------------
' 3. QTABCONTROL - extra funcs for adding/editing TABs when ONLY the handle is
' available (an unfortunate legacy when creating components at the "local" level).
'
' Some of the uMsg constants
$DEFINE TCM_SETIMAGELIST &H1303
$DEFINE TCM_GETITEMCOUNT &H1304
$DEFINE TCM_SETITEM &H1306
$DEFINE TCM_INSERTITEM &H1307
$DEFINE TCM_DELETEITEM &H1308
$DEFINE TCM_DELETEALLITEMS &H1309
$DEFINE TCM_GETITEMRECT &H130A
' Mask values
$DEFINE TCIF_TEXT &H1
$DEFINE TCIF_IMAGE &H2
$DEFINE TCIF_RTLREADING &H4
$DEFINE TCIF_PARAM &H8
$DEFINE TCIF_STATE &H10

TYPE TabTCITEMHEADER
mask AS long
Reserved1 AS long
Reserved2 AS long
lpszText AS long
cchTextMax AS integer
iImage AS integer
END TYPE

'*****************************************
FUNCTION GetTabCount(TabHandle AS long) AS integer
Result=SendMessageAPI(TabHandle, TCM_GETITEMCOUNT, 0, 0)
END FUNCTION

'*****************************************
FUNCTION DelAllTabs(TabHandle AS long) AS integer
Result=0
IF GetTabCount(TabHandle)>0 THEN
	Result=SendMessageAPI(TabHandle, TCM_DELETEALLITEMS, 0, 0)
END IF
END FUNCTION

'*****************************************
' NB IF TabIndex>=numTabs - just adds to end - else will insert between TABs
FUNCTION AddNewTab(TabHandle AS long, TabIndex AS integer, TabText AS string) AS integer
DEFSTR tmpString
DIM TabHdr AS TabTCITEMHEADER

Result=0
IF TabIndex<0 THEN EXIT FUNCTION
tmpString=TabText+CHR$(0)                                       ' Ensure Null termination
TabHdr.lpszText=VARPTR(tmpString)                               ' Ptr to string
TabHdr.mask=TCIF_TEXT                                           ' Set mask
TabHdr.iImage=-1                                                ' image index or -1
Result=SendMessageAPI(TabHandle, TCM_INSERTITEM, TabIndex, TabHdr)      ' returns index #
END FUNCTION

'---------------------------------------------------------------------------------------------------------
' My kludge to create multiple QOvalBtns AND be able to set the caption.
' Uses global arrays of QPanel & QCanvas **JUST** to do this!!
' Tried ~1000 other ways, with only a handle, and ALL failed!
' NB QCANVAS (and QIMAGE) "Handle" property is NOT a handle.
' The imgOval.Tag property holds the index of the array item
' when an oval button is added. The imgOval has the focus and
' the OnClick function OvalPaint() uses this (.Tag) index.
'
' DON'T TRY THIS AT HOME KIDS - I AM A Prufess....er PRefissh....er  ... OK it's a kludge!
'
' The GLOBAL declarations for the QOvalBtn object
DIM panOval(1) AS QPANEL                                            ' An array of global panels
DIM imgOval(1) AS QCANVAS                                           ' Array of global (child) Canvas's

' Functions to set/repaint the QOvalBtns

'*****************************************
' OnClick event of QCANVAS
SUB OvalPaint(Sender AS QCANVAS)
DEFINT i
DEFSTR cap

WITH Sender
	i=.Tag                                                          ' Holds the index of the array
	cap=panOval(i).Caption                                          ' Caption from the QPANEL
	.Circle(0,0,.Width,.Height,0,clBtnFace)                         ' backcolor - erases old caption
	i=.TextWidth(cap)
	WHILE i>.Width
		cap=LEFT$(cap,LEN(cap)-1)                                   ' IF too big, adjust caption to fit
		i=.TextWidth(cap)
	WEND
	.TextOut((.Width-i)\2,(.Height-.TextHeight("#_"))\2,cap,0,-1)   ' Centred text
END WITH
END SUB

'*****************************************
' Called in code, when QOvalBtn(idx) needs updating
SUB OvalRepaint(idx AS integer,X AS integer,Y AS integer,W AS integer,H AS integer,cap AS string)
panOval(idx).Left=X
panOval(idx).Top=Y
panOval(idx).Width=W
panOval(idx).Height=H
panOval(idx).Caption=cap
imgOval(idx).RePaint                                            ' This calls the above SUB
END SUB

'----------------------------- Program component defines -----------------------------------------
' NB: These are in order as per the Toolbar bmps, component.data file and button select (and other)
' code in the main program!!
'-------------------------------------------------------------------------------------------------
' Visible components
$DEFINE Q_FORM          0
$DEFINE Q_EDIT          1
$DEFINE Q_RICHEDIT      2
$DEFINE Q_LABEL         3
$DEFINE Q_BUTTON        4
$DEFINE Q_COOLBTN       5
$DEFINE Q_OVALBTN       6
$DEFINE Q_CHECKBOX      7
$DEFINE Q_RADIOBUTTON   8
$DEFINE Q_PANEL         9
$DEFINE Q_TABCONTROL    10
$DEFINE Q_COMBOBOX      11
$DEFINE Q_LISTBOX       12
$DEFINE Q_GROUPBOX      13
$DEFINE Q_SCROLLBOX     14
$DEFINE Q_SCROLLBAR     15
$DEFINE Q_STRINGGRID    16
$DEFINE Q_LISTVIEW      17
$DEFINE Q_DIRTREE       18
$DEFINE Q_FILELISTBOX   19
$DEFINE Q_TREEVIEW      20
$DEFINE Q_OUTLINE       21
$DEFINE Q_GAUGE         22
$DEFINE Q_TRACKBAR      23
$DEFINE Q_HEADER        24
$DEFINE Q_STATUSBAR     25
$DEFINE Q_CANVAS        26
$DEFINE Q_IMAGE         27
$DEFINE Q_OLECONTAINER  28
$DEFINE Q_SPLITTER      29
' Non-visible
$DEFINE Q_BITMAP        30
$DEFINE Q_IMAGELIST     31
$DEFINE Q_STRINGLIST    32
$DEFINE Q_TIMER         33
$DEFINE Q_SOCKET        34
$DEFINE Q_FILESTREAM    35
$DEFINE Q_MEMORYSTREAM  36
$DEFINE Q_FONT          37
$DEFINE Q_MYSQL         38
$DEFINE Q_OLEOBJECT     39
$DEFINE Q_REGISTRY      40
' Dialogs
$DEFINE Q_OPENDIALOG    41
$DEFINE Q_SAVEDIALOG    42
$DEFINE Q_FONTDIALOG    43
$DEFINE Q_COLORDIALOG   44
' Q_D3D
$DEFINE Q_DXTimer       45
$DEFINE Q_DXSound       46
$DEFINE Q_DXScreen      47
$DEFINE Q_DXImageList   48
$DEFINE Q_D3DFace       49
$DEFINE Q_D3DMeshBuilder    50
$DEFINE Q_D3DFrame      51
$DEFINE Q_D3DLight      52
$DEFINE Q_D3DTexture    53
$DEFINE Q_D3DVector     54
$DEFINE Q_D3DWrap       55
$ENDIF   ' IncManager: __RAPIDFRM_INC
