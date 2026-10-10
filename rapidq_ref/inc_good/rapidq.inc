'    RAPIDQ.INC  -- Include file for RAPID-Q by William Yu
'             -- attach a $INCLUDE "RAPIDQ.INC"
'             -- to all your programs, or just extract what you need.

  'ввввввв
'$IFNDEF space
$DEFINE space space$
'$ENDIF

$DEFINE Boolean byte
$DEFINE MsgBox Showmessage

$DEFINE chr chr$
$DEFINE mid mid$
$DEFINE fileexist fileexists 

$define  int integer 
defstr vbNullString=""
$define #define $define

' вариант комментария
$define !!! rem
$define !!!! '
$define !! '

$define #define $define

$define brem $ifdef 
$define erem $endif

$define remb $ifdef 
$define reme $endif


dim ErrorMsg$ as string
ErrorMsg$="No errors"

defstr infomsg$=""


'!!! ------------------------- Useful variables ------------
$define  False  0
$define True  1
$define pi 3.14159

$define ascb asc

Const Base64Table As String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"


CONST  CRLF= chr$(13)+chr$(10)'' "\r\n"    ' chr$(13)+chr$(10)

CONST vbcrlf= chr$(13)+chr$(10)
CONST HT =chr$(9)
CONST  CR =chr$(13)
CONST  LF =chr$(10)
CONST  QT =chr$(34)
CONST  BkSl= chr$(92)
CONST  BSl =chr$(92)
CONST  aps =chr$(39)
CONST sp =chr$(32)

$DEFINE tpTop    0
$DEFINE tpBottom 1
$DEFINE tpLeft   2
$DEFINE tpRight  3


'!!!-- Control Alignments
CONST alNone = 0
CONST alTop = 1
CONST alBottom = 2
CONST alLeft = 3
CONST alRight = 4
CONST alClient = 5           '-- Expand to fit client

'!!!-- Text Alignments
CONST taLeftJustify = 0
CONST taRightJustify = 1
CONST taCenter = 2

CONST SND_SYNC = 0           '-- Synchronous playback (Wait for sound to finish)
CONST SND_ASYNC = 1          '-- Asynchronous playback (Like background play).
CONST SND_LOOP = 8           '-- Loop sound

'!!!-- BASIC Colors
CONST clBlack = 0
'-- BGR
CONST clBlue = &HFF0000  '256
CONST clLBlue = &HFFaa00  '256clLtBlue
CONST clLtBlue = &HFFaa00  '256clLtBlue
CONST clDBlue = &H800000 '128
CONST clB = &HFF0000  '256
CONST clLB = &HFFaa00  '256clLtBlue
CONST clDB = &H800000 '128


CONST clMaroon = &H808000
CONST clM = &H808000

CONST clGreen = &H00FF00
CONST clDGreen = &H008000
CONST clG = &H00FF00
CONST clDG = &H008000

CONST clLRed = &H8080FF
CONST clRed =   &H0000FF
CONST clDRed = &H000080
CONST clLR = &H8080FF
CONST clR =   &H0000FF
CONST clDR = &H000080

CONST clPurple = &HFF00FF
CONST clDPurple =&h800080
CONST clP = &HFF00FF
CONST clDP =&h800080

CONST clLMagenta = &HFF00FF
CONST clMagenta =&h800080
CONST clLMg = &HFF00FF
CONST clMg =&h800080

CONST clSilver = &hc0c0c0
CONST clSl = &hc0c0c0
CONST clGrey=&h808080
CONST clGray=&h808080
CONST clDGray=&h808080
CONST clDGrey=&h808080
CONST clWhite = &HFFFFFF
CONST clW = &HFFFFFF

CONST clAqua=&hffff00
CONST clLAqua=&hfffff0
CONST clA=&hffff00
CONST clLA=&hfffff0

CONST clyellow=&h00ffff
CONST cly=&h00ffff
CONST clBrown=&h008080
CONST clOrange=&h0080FF
CONST clOr=&h0080FF
CONST clO=&h0080FF
'CONST cl

'!!!-- System colors
CONST clScrollBar = -2147483648
CONST clBackGround = -2147483647
CONST clActiveCaption = -2147483646
CONST clInActiveCaption = -2147483645
CONST clMenu = -2147483644
CONST clWindow = -2147483643
CONST clWindowFrame = -2147483642
CONST clMenuText = -2147483641
CONST clWindowText = -2147483640
CONST clCaptionText = -2147483639
CONST clActiveBorder = -2147483638
CONST clInActiveBorder = -2147483637
CONST clAppWorkSpace = -2147483636
CONST clHilight = -2147483635
CONST clHilightText = -2147483634
CONST clBtnFace = -2147483633
CONST clBtnShadow = -2147483632
CONST clGrayText = -2147483631
CONST clBtnText = -2147483630
CONST clInActiveCaptionText = -2147483629
CONST clBtnHighlight = -2147483628
CONST cl3DDkShadow = -2147483627
CONST cl3DLight = -2147483626
CONST clInfoText = -2147483625
CONST clInfoBk3DDkShadow = -2147483624
CONST clNone = 536870911
CONST clDefault = 536870912

'!!!-- Mouse Shift States, True if Shift% AND ss<State>
CONST ssShift = 256
CONST ssCtrl = 16
CONST ssAlt = 1

'!!!-- MessageDlg Message Types
CONST mtWarning = 0
CONST mtError = 1
CONST mtInformation = 2
CONST mtConfirmation = 3
CONST mtCustom = 4

'!!!-- MessageDlg Message Buttons (NOT QBUTTON)
CONST mbYes = 1          ' YES Button
CONST mbNo = 2           ' NO Button
CONST mbOK = 4           ' OK Button
CONST mbCancel = 8       ' etc. etc.
CONST mbHelp = 16
CONST mbAbort = 32
CONST mbRetry = 64
CONST mbIgnore = 128
CONST mbAll = 256

'-- MessageDlg Return Values: See ModalResult of QButton

'!!! -- MessageBox Buttons

Public Const MB_OK = &H0
Public Const MB_OKCANCEL = &H1
Public Const MB_ABORTRETRYIGNORE = &H2
Public Const MB_YESNOCANCEL = &H3
Public Const MB_YESNO = &H4
Public Const MB_RETRYCANCEL = &H5

Public Const MB_ICONHAND = &H10
Public Const MB_ICONQUESTION = &H20
Public Const MB_ICONEXCLAMATION = &H30
Public Const MB_ICONASTERISK = &H40

Public Const MB_ICONINFORMATION = MB_ICONASTERISK
Public Const MB_ICONSTOP = MB_ICONHAND

Public Const MB_DEFBUTTON1 = &H0
Public Const MB_DEFBUTTON2 = &H100
Public Const MB_DEFBUTTON3 = &H200

Public Const MB_APPLMODAL = &H0
Public Const MB_SYSTEMMODAL = &H1000
Public Const MB_TASKMODAL = &H2000

Public Const MB_NOFOCUS = &H8000
Public Const MB_SETFOREGROUND = &H10000
Public Const MB_DEFAULT_DESKTOP_ONLY = &H20000

Public Const MB_TYPEMASK = &HF
Public Const MB_ICONMASK = &HF0
Public Const MB_DEFMASK = &HF00
Public Const MB_MODEMASK = &H3000
Public Const MB_MISCMASK = &HC000

'!!! ------------------------- QRegistry Variables --------------------------

Public Const HKEY_CLASSES_ROOT = &H80000000
Public Const HKEY_CURRENT_USER = &H80000001
Public Const HKEY_LOCAL_MACHINE = &H80000002
Public Const HKEY_USERS = &H80000003
Public Const HKEY_PERFORMANCE_DATA = &H80000004
Public Const HKEY_CURRENT_CONFIG = &H80000005
Public Const HKEY_DYN_DATA = &H80000006


'!!! ------------------------- QFONT Variables --------------------------
'-- Font Styles
CONST fsBold = 0
CONST fsItalic = 1
CONST fsUnderline = 2
CONST fsStrikeOut = 3

'-- Font Pitch
CONST fpDefault = 0           '-- Depends on the font specified
CONST fpVariable = 1          '-- Characters in font have different widths
CONST fpFixed = 2             '-- Characters in font have same widths

'-- Font Character sets
CONST ANSI_CHARSET = 0        '-- ANSI characters
CONST DEFAULT_CHARSET = 1
CONST SYMBOL_CHARSET = 2      '-- Standard symbol set
CONST MAC_CHARSET = 77        '-- Macintosh characters
CONST SHIFTJIS_CHARSET = 128  '-- Japanese shift-jis characters
CONST HANGEUL_CHARSET = 129
CONST JOHAB_CHARSET = 130
CONST GB2312_CHARSET = 134
CONST CHINESEBIG5_CHARSET = 136
CONST GREEK_CHARSET = 161
CONST TURKISH_CHARSET = 162
CONST VIETNAMESE_CHARSET = 163
CONST HEBREW_CHARSET = 177
CONST ARABIC_CHARSET = 178
CONST BALTIC_CHARSET = 186
CONST RUSSIAN_CHARSET = 204
CONST THAI_CHARSET = 222
CONST EASTEUROPE_CHARSET = 238
CONST OEM_CHARSET = 255       '-- Depends on the codepage of the OS


'!!! ------------------------- QFORM Variables --------------------------
'-- Window States
CONST wsNormal = 0
CONST wsMinimized = 1
CONST wsMaximized = 2

'-- Form Styles
CONST fsNormal = 0
CONST fsMDIChild = 1
CONST fsMDIForm = 2
CONST fsStayOnTop = 3

'-- Border Styles
CONST bsNone = 0              '-- No visible border line, Not resizeable
CONST bsSingle = 1            '-- Single-line border, Not resizeable
CONST bsSizeable = 2          '-- Standard resizeable border
CONST bsDialog = 3            '-- Dialog, not resizeable
CONST bsToolWindow = 4        '-- like bsSingle but with a smaller caption
CONST bsSizeToolWin = 5       '-- like bsSizeable with a smaller caption

'-- Keyboard Shift States
CONST CtrlDown = 1
CONST AltDown = 16
CONST ShiftDown = 256

'-- Border Icons
CONST biSystemMenu = 0
CONST biMinimize = 1
CONST biMaximize = 2
CONST biHelp = 3

'-- Close Actions
CONST caNone = 0              '-- Don't close the form
CONST caHide = 1              '-- Just hide the form
CONST caFree = 2
CONST caClose = caFree        '-- Close form
CONST caMinimize = 3          '-- Minimize instead of closing


'!!! ------------------------- QLABEL Variables -------------------------
'-- Text Layout
CONST tlTop = 0
CONST tlCenter = 1
CONST tlBottom = 2

'-- Label Style
CONST lsNone = 0
CONST lsRaised = 1
CONST lsRecessed = 2


'!!! ------------------------- QPANEL Variables -------------------------
'-- Bevel Style
CONST bvNone = 0
CONST bvLowered = 1
CONST bvRaised = 2

'-- Bevel Border
CONST bpNone = 0         '-- No visible border
CONST bpSingle = 1       '-- Single-line border


'!!! ------------------------- QEDIT Variables --------------------------
'-- CharCase
CONST ecNormal = 0       '-- Text of the edit box displays in mixed case
CONST ecUpperCase = 1    '-- Text of the edit box displays in uppercase
CONST ecLowerCase = 2    '-- Text of the edit box displays in lowercase


'!!! ----------------------- QCOMBOBOX Variables ------------------------
'-- ComboBox Styles
CONST csDropDown = 0           '-- Drop-down list with an edit box
CONST csSimple = 1             '-- Edit box with no list.
CONST csDropDownList = 2       '-- Drop-down list without an edit box
CONST csOwnerDrawFixed = 3     '-- Owner draw fixed
CONST csOwnerDrawVariable = 4  '-- Owner draw variable


'!!! ---------------------- QFILESTREAM Variables -----------------------
'-- File Mode
CONST fmCreate = 65535
CONST fmOpenRead = 0
CONST fmOpenWrite = 1
CONST fmOpenReadWrite = 2

'-- Offsets
CONST soFromBeginning = 0       '-- Seek (offset) from Beginning
CONST soFromCurrent = 1         '-- Seek (offset) from Current position
CONST soFromEnd = 2             '-- Seek (offset) from End

'-- Read/Write Numbers
CONST Num_BYTE   = 1            '-- ie. PRINT File.ReadNum(Num_SINGLE)
CONST Num_SHORT  = 2
CONST Num_WORD   = 3
CONST Num_LONG   = 4
CONST Num_DWORD  = 5
CONST Num_SINGLE = 6
CONST Num_DOUBLE = 8


'!!! ----------------------- QRICHEDIT Variables ------------------------
'-- Scroll Bars
CONST ssNone = 0
CONST ssHorizontal = 1
CONST ssVertical = 2
CONST ssBoth = 3


'!!! ---------------------- MODALRESULT Variables -----------------------
'-- Default ModalResults
CONST mrNone = 0
CONST mrOK = 1
CONST mrCancel = 2
CONST mrAbort = 3
CONST mrRetry = 4
CONST mrIgnore = 5
CONST mrYes = 6
CONST mrNo = 7
CONST mrAll = 8
'CONST MB_YESNO
CONST mrNoToAll = 9
CONST mrYesToAll = 10


'!!! ------------------------ QBUTTON Variables -------------------------
'-- Bitmap Alignment
CONST blBMPLeft = 0
CONST blBMPRight = 1
CONST blBMPTop = 2
CONST blBMPBottom = 3

'-- Button Kind
CONST bkCustom = 0              '-- None
CONST bkOK = 1                  '-- Check Bitmap
CONST bkCancel = 2              '-- X Bitmap
CONST bkHelp = 3                '-- ? Bitmap
CONST bkYes = 4
CONST bkNo = 5
CONST bkClose = 6
CONST bkAbort = 7
CONST bkRetry = 8
CONST bkIgnore = 9
CONST bkAll = 10


'!!! ------------------------ CURSORS Variables -------------------------
CONST crDefault = 0        ' Normal pointer
CONST crNone = -1
CONST crArrow = -2
CONST crCross = -3
CONST crIBeam = -4
CONST crSize = -5
CONST crSizeNESW = -6
CONST crSizeNS = -7
CONST crSizeNWSE = -8
CONST crSizeWE = -9
CONST crUpArrow = -10
CONST crHourGlass = -11
CONST crDrag = -12
CONST crNoDrop = -13
CONST crHSplit = -14
CONST crVSplit = -15
CONST crMultiDrag = -16
CONST crSQLWait = -17
CONST crNo = -18
CONST crAppStart = -19
CONST crHelp = -20
CONST crHandPoint = -21


'!!! --------------------- QFILELISTBOX Variables -----------------------
'-- FileTypes
CONST ftReadOnly = 0     '-- Display files with read-only attribute
CONST ftHidden = 1       '--   "       "     "  hidden attribute
CONST ftSystem = 2       '-- Displays system files
CONST ftVolumeID = 3     '-- Displays the volume name
CONST ftDirectory = 4    '-- Displays directories
CONST ftArchive = 5      '-- Display files with archive attribute
CONST ftNormal = 6       '-- Display files with no special attributes


'!!! ---------------------- QSCROLLBAR Variables ------------------------
'-- Kind
CONST sbHorizontal = 0
CONST sbVertical = 1

'-- ScrollCode
CONST scLineUp = 0
CONST scLineDown = 1
CONST scPageUp = 2
CONST scPageDown = 3
CONST scPosition = 4
CONST scTrack = 5
CONST scTop = 6
CONST scBottom = 7
CONST scEndScroll = 8


'!!! ----------------------- QIMAGELIST Variables -----------------------
'-- Draw styles
CONST dsFocused = 0      '-- Draws the image blending 25% with the system
'   highlight color. This only affects imagelists
'   which contain masks.
CONST dsSelected = 1     '-- Draws the image blending 50%
CONST dsNormal = 2       '-- Draws the image using the color specified in
'   the BkColor property
CONST dsTransparent = 3  '-- Draws using the mask regardless of the BkColor
'   setting

'-- Image type
CONST itImage = 0        '-- Draw image
CONST itMask = 1         '-- Draw image mask


'!!! ------------------ QLISTVIEW/QTREEVIEW Variables -------------------
'-- Sort Type
CONST stNone = 0         '-- Sort Type: None
'CONST stData = 1
CONST stText = 2
'CONST stBoth = 3

'-- QLISTVIEW View Style
CONST vsIcon = 0         '-- View Style: Full sized icon, text on bottom
CONST vsSmallIcon = 1    '-- Small icons, text aligned to the right
CONST vsList = 2         '-- Same as above (nevermind this)
CONST vsReport = 3       '-- Each item appears on its own line with information
'-- arranged in columns

'!!! ----------------------- QTRACKBAR Variables ------------------------
CONST tbHorizontal = 0   '-- TrackBar Orientation
CONST tbVertical = 1

CONST tmBottomRight = 0  '-- Tickmark placement
CONST tmTopLeft = 1
CONST tmBoth = 2

CONST tsNone = 0         '-- Track bar displays no tick marks
CONST tsAuto = 1         '-- Track bar displays tick marks automatically
'   for each increment in its range
CONST tsManual = 2       '-- Track bar displays a tick mark at either end


'!!! ---------------------- QSTRINGGRID Variables -----------------------
CONST goFixedVertLine = 0'-When True, horizontal lines appear between the rows
'-within nonscrolling regions.

CONST goFixedHorzLine = 1'-When True, vertical lines appear between the columns
'-within nonscrolling regions.

CONST goVertLine = 2 '- When True, horizontal lines appear between the rows.

CONST goHorzLine = 3
CONST goRangeSelect = 4
CONST goDrawFocusSelected = 5
CONST goRowSizing = 6
CONST goColSizing = 7
CONST goRowMoving = 8
CONST goColMoving = 9
CONST goEditing = 10
CONST goTabs = 11
CONST goRowSelect = 12
CONST goAlwaysShowEditor = 13
CONST goThumbTracking = 14

'- goVertLine     
' When True, vertical lines appear between the columns.
'goRangeSelect   When True, the user can select a range of cells at one
'time. When goEditing is True, the user can no longer select a range of
'cells.

'- goDrawFocusSelected   
'  When True, the cell with the focus is colored
'the same as other cells in a selected block are colored. When False, the
'cell with the focus remains the color of all unselected cells, the color
'specified with the grid Color property.

'- goRowSizing    
' When True, rows can be resized individually except for
'fixed or nonscrolling rows.

'- goColSizing   
'  When True, columns can be resized individually except
'for fixed or nonscrolling columns.

'- goRowMoving   
'  When True, the user can move a row to a new location in
'the grid using the mouse.

'-goColMoving  
'   When True, the user can move a column to a new location
'in the grid using the mouse.

'-goEditing  
'     When True, the user can edit the text in the grid. When
'goEditing is True, the user cannot select a range of cells at one time.

'-goAlwaysShowEditor   
'   When True, the grid is in automatic edit mode
'if goEditing is also True. When the grid is in automatic edit mode, the
'user does not have to press Enter or F2 before editing the contents of a
'cell. When goAlwaysShowEditor is False and goEditing is True, the user
'must press Enter or F2 before editing the contents of a cell. If
'goEditing is False, setting goAlwaysShowEditor to True has no effect.


'-goTabs  
'When True, the user can use the Tab and Shift-Tab keys to move
'from column to column in the grid.

'-goRowSelect
'     When True, the user can only whole rows at a time
'instead of individual cells.

'-goThumbTracking 
'When True, the contents of the grid scrolls while the
'user is moving the thumb tab of the grid scroll bar. When False, the
'contents of the grid doesn't scroll until the user releases the thumb
'tab in its new position.

'-- ColumnStyles
CONST gcsList = 0
CONST gcsEllipsis = 1
CONST gcsNone = 2


'!!! ----------------------- QOUTLINE Variables -------------------------
'-- Outline Style
CONST osText = 0
CONST osPlusMinusText = 1
CONST osPictureText = 2
CONST osPlusMinusPictureText = 3
CONST osTreeText = 4
CONST osTreePictureText = 5

'-- Outline options
CONST ooDrawTreeRoot = 0         '-- First item is connected to the root item
CONST ooDrawFocusRect = 1        '-- Draw focus retangle around selected item
CONST ooDrawStretchBitmaps = 2   '-- Stretch bitmap to fit size of item


'!!! ------------------------ QGAUGE Variables --------------------------
'-- Kinds
CONST gkText = 0
CONST gkHorizontalBar = 1
CONST gkVerticalBar = 2
CONST gkPie = 3
CONST gkNeedle = 4


'!!! ----------------- QBITMAP/QCANVAS/QIMAGE Variables -----------------
'-- CopyMode
CONST cmBlackness = 0     ' Fill Destination rectange on the canvas with black
CONST cmDstInvert = 1
CONST cmMergeCopy = 2
CONST cmMergePaint = 3
CONST cmNotSrcCopy = 4
CONST cmNotSrcErase = 5
CONST cmPatCopy = 6
CONST cmPatInvert = 7
CONST cmPatPaint = 8
CONST cmSrcAnd = 9
CONST cmSrcCopy = 10      ' Copies source image to the canvas
CONST cmSrcErase = 11
CONST cmSrcInvert = 12
CONST cmSrcPaint = 13
CONST cmWhiteness = 14    ' Fill Destination rectange on the canvas with white

'-- QBITMAP Pixel Formats
CONST pfDevice = 0
CONST pf1bit = 1
CONST pf4bit = 2
CONST pf8bit = 3
CONST pf15bit = 4
CONST pf16bit = 5
CONST pf24bit = 6
CONST pf32bit = 7

'-- QBITMAP TransparentMode
CONST tmAuto  = 0
CONST tmFixed = 1


'!!! ------------------------ QLISTBOX Variables ------------------------
'-- ListBox Styles
CONST lbStandard = 0           '-- All items are strings
CONST lbOwnerDrawFixed = 1     '-- Owner draw fixed
CONST lbOwnerDrawVariable = 2  '-- Owner draw variable


'!!! ------------------------ QCOMPORT Variables ------------------------
'-- Baud Rates
$IFDEF __COMPORT
CONST br110 = 0
CONST br300 = 1
CONST br600 = 2
CONST br1200 = 3
CONST br2400 = 4
CONST br4800 = 5
CONST br9600 = 6
CONST br14400 = 7
CONST br19200 = 8
CONST br38400 = 9
CONST br56000 = 10
CONST br57600 = 11
CONST br115200 = 12

'-- Stop bits
CONST sbOneStopBit = 0
CONST sbOne5StopBits = 1
CONST sbTwoStopBits = 2

'-- Parity
CONST prNone = 0
CONST prOdd = 1
CONST prEven = 2
CONST prMark = 3
CONST prSpace = 4
$ENDIF

'!!! ---------------------- QFONTDIALOG Variables -----------------------
'-- Font Options
CONST fdAnsiOnly = 0             '-- No weird symbols
CONST fdTrueTypeOnly = 1
CONST fdEffects = 2
CONST fdFixedPitchOnly = 3
CONST fdForceFontExist = 4
CONST fdNoFaceSel = 5
CONST fdNoOEMFonts = 6
CONST fdNoSimulations = 7
CONST fdNoSizeSel = 8
CONST fdNoStyleSel = 9
CONST fdNoVectorFonts = 10
CONST fdShowHelp = 11
CONST fdWysiwyg = 12
CONST fdLimitSize = 13
CONST fdScalableOnly = 14
CONST fdApplyButton = 15


'!!! ----------------------- QDIRTREE Variables -------------------------
'-- DirTypes
CONST dtReadOnly = 0
CONST dtHidden = 1
CONST dtSystem = 2
CONST dtNormal = 3
CONST dtAll = 4

'-- DriveTypes
CONST drtUnknown = 0
CONST drtRemovable = 1
CONST drtFixed = 2
CONST drtRemote = 3
CONST drtCDRom = 4
CONST drtRamDisk = 5


'!!! ------------------------ QSOCKET Variables -------------------------
'-- Protocols
CONST IPPROTO_IP   = 0        ' dummy for IP
CONST IPPROTO_ICMP = 1        ' control message protocol
CONST IPPROTO_IGMP = 2        ' group management protocol
CONST IPPROTO_TCP  = 6
CONST IPPROTO_PUP  = 12
CONST IPPROTO_UDP  = 17       ' user datagram protocol
CONST IPPROTO_IDP  = 22       ' xns idp
CONST IPPROTO_RAW  = 255      ' raw IP packet

'-- Socket Types
CONST SOCK_STREAM    = 1      ' stream socket
CONST SOCK_DGRAM     = 2      ' datagram socket
CONST SOCK_RAW       = 3      ' raw-protocol interface
CONST SOCK_RDM       = 4      ' reliably-delivered message
CONST SOCK_SEQPACKET = 5      ' sequenced packet stream

'-- Address families
CONST AF_UNSPEC    = 0        ' unspecified
CONST AF_UNIX      = 1        ' local to host (pipes, portals)
CONST AF_INET      = 2        ' internetwork: UDP, TCP, etc.
CONST AF_IMPLINK   = 3        ' arpanet imp addresses
CONST AF_PUP       = 4        ' pup protocols: e.g. BSP
CONST AF_CHAOS     = 5        ' mit CHAOS protocols
CONST AF_IPX       = 6        ' IPX and SPX
CONST AF_NS        = 6        ' XEROX NS protocols
CONST AF_ISO       = 7        ' ISO protocols
CONST AF_OSI       = AF_ISO
CONST AF_ECMA      = 8        ' european computer manufacturers
CONST AF_DATAKIT   = 9        ' datakit protocols
CONST AF_CCITT     = 10       ' CCITT protocols, X.25 etc
CONST AF_SNA       = 11       ' IBM SNA
CONST AF_DECnet    = 12       ' DECnet
CONST AF_DLI       = 13       ' Direct data link interface
CONST AF_LAT       = 14       ' LAT
CONST AF_HYLINK    = 15       ' NSC Hyperchannel
CONST AF_APPLETALK = 16       ' AppleTalk
CONST AF_NETBIOS   = 17       ' NetBios-style addresses
CONST AF_VOICEVIEW = 18       ' VoiceView
CONST AF_FIREFOX   = 19       ' FireFox
CONST AF_UNKNOWN1  = 20       ' What?
CONST AF_BAN       = 21       ' Banyan


'!!! ----------------------- QHEADER Variables --------------------------
'-- Header Styles
CONST hsText = 0
CONST hsOwnerDraw = 1


'!!! --------------------- QSTRINGLIST Variables ------------------------
'-- Duplicates
CONST dupIgnore = 0
CONST dupAccept = 1
CONST dupError = 2


'!!! -------------------- QOLECONTAINER Variables -----------------------
'-- Size Mode
CONST smClip = 0              '-- Clip parts that don't fit inside
CONST smCenter = 1            '-- Center object within the container
CONST smScale = 2             '-- Scales or shrinks object to fit inside
CONST smStretch = 3           '-- Stretch to fill entire container
CONST smAutoSize = 4          '-- Sizes container to match size of object

'-- Object States
CONST osEmpty = 0
CONST osLoaded = 1
CONST osRunning = 2
CONST osOpen = 3
CONST osInPlaceActive = 4
CONST osUIActive = 5


'!!! --------------------- STRF$ Format Variables -----------------------
CONST ffGeneral = 0
CONST ffExponent = 1
CONST ffFixed = 2
CONST ffNumber = 3


'!!! ------------------------- DIR$ Variables ---------------------------
'-- File Attributes
CONST faReadOnly  = 1
CONST faHidden    = 2
CONST faSysFile   = 4
CONST faVolumeID  = 8
CONST faDirectory = 16
CONST faArchive   = 32
CONST faAnyFile   = 63


'!!! ------------------------ PRINTER Variables -------------------------
'-- Orientations
CONST poPortrait  = 0
CONST poLandscape = 1


'!!! ---------------------------- QBColor -------------------------------

'$IFDEF __QBCOLOR
DIM QBColor(0 TO 15) AS INTEGER
QBColor(0) = 0               '-- Black
QBColor(1) = &H800000        '-- Blue
QBColor(2) = &H8000          '-- Green
QBColor(3) = &H808000        '-- Cyan
QBColor(4) = &H80            '-- Red
QBColor(5) = &H800080        '-- Magenta
QBColor(6) = &H8080          '-- Brown
QBColor(7) = &HC0C0C0        '-- White
QBColor(8) = &H808080        '-- Grey
QBColor(9) = &HFF0000        '-- Light Blue
QBColor(10) = &HFF00         '-- Light Green
QBColor(11) = &HFFFF00       '-- Light Cyan
QBColor(12) = &HFF           '-- Light Red
QBColor(13) = &HFF00FF       '-- Light Magenta
QBColor(14) = &HFFFF         '-- Yellow
QBColor(15) = &HFFFFFF       '-- Bright White
'$ENDIF ' __QBCOLOR

'$ENDIF ' __RQINC


DIM QBColorLi(0 TO 15) AS INTEGER
QBColorLi(0) = 0               '-- Black
QBColorLi(1) = &H800000        '-- Blue
QBColorLi(2) = &H8000          '-- Green
QBColorLi(3) = &H808000        '-- Cyan
QBColorLi(4) = &H80            '-- Red
QBColorLi(5) = &H800080        '-- Magenta
QBColorLi(6) = clp          '-- Brown
QBColorLi(7) = &HC0C0C0        '-- White
QBColorLi(8) = clb        '-- Grey
QBColorLi(9) = &HC0C0C0 'clo        '-- orange
QBColorLi(10) = &HFF00       '-- Light Green
QBColorLi(11) = &HFF          '-- Light red
QBColorLi(12) = &HFFFF00       '-- Aqua 
QBColorLi(13) = &HFF00FF       '-- Light Magenta
QBColorLi(14) = &HFFFF         '-- Yellow
QBColorLi(15) = &HFFFFFF       '-- Bright White
'$ENDIF ' __QBCOLOR


#define CP_ACP  0
#define CP_OEMCP 1
#define CP_MACCP 2


#define CP_NIL    (-1)
#define CP_SYMBOL   42
#define CP_OEM_437   437
#define CP_THAI    874
#define CP_JAPAN   932
#define CP_CHINA   936
#define CP_KOREA   949
#define CP_TAIWAN   950
#define CP_EASTEUROPE  1250
#define CP_RUSSIAN   1251
#define CP_WESTEUROPE  1252
#define CP_GREEK   1253
#define CP_TURKISH   1254
#define CP_HEBREW   1255
#define CP_ARABIC   1256
#define CP_BALTIC   1257
#define CP_JOHAB   1361
#define CP_MAC_ROMAN  10000
#define CP_MAC_JAPAN  10001
#define CP_MAC_GREEK  10006
#define CP_MAC_CYRILLIC  10007
#define CP_MAC_LATIN2  10029
#define CP_MAC_TURKISH  10081
#define CP_UTF8    65001

'!!! ------------------------------ custom function ------------------------'

'-- ***********************************************************************'
sub AddClrString (AddString$, Clr, Sender as QRICHEDIT)
'Add colored string to QRICHEDIT
Sender.SelStart =len (Sender.Text)
Sender.SelLength =Len(AddString$)
Sender.SelAttributes.Color=Clr
Sender.AddStrings AddString$
end sub
'-- ***********************************************************************'
sub AddFontString (AddString$, FontStr as QFont, Sender as QRICHEDIT)
'Add colored string to QRICHEDIT
Sender.SelStart =len (Sender.Text)
Sender.SelLength =Len(AddString$)
Sender.SelAttributes.Color=FontStr.Color
Sender.SelAttributes.Name=FontStr.Name
Sender.AddStrings AddString$
end sub


'-- ***********************************************************************'
Function fTally (sSearchIn As String, sToFind As string) As Long
DefInt iCharCounter = 0
For N = 1 To Len(sSearchIn)
	If sSearchIn[N] = sToFind Then iCharCounter ++
Next N
Result = iCharCounter
End Function

'-- ***********************************************************************'
Function Trim$(s as string) as string
Result=LTRIM$(RTRIM$(s))
End Function


'--- Declarations ---
declare Function GetSubjCodePage( Subject As String) As String
declare Function GetSubjCodeMethod( Subject As String) As String
declare Function GetMsgBodyContentType ( Msg As String) As String
declare Function GetMsgBodyCodePage ( Msg As String) As String
declare Function GetMsgBodyCodeMethod( Msg As String) As String
declare Function GetHeaderField( Header As String, Field as string) As String
declare Function GetMSGHeader( Source As String) As String
declare Function GetMSGBody( Source As String) As String 
declare Function isKOI8( Red$ As String) As long
declare Function RQBASE64Encode(s As String) As String
declare Function RQBASE64Decode (stxt As String) As String
declare Function DecodeSubj( Subject As String) As String 
declare Function RQConvertCodePage (SourseString As String, inPage As long, outPage As long) As String

Declare Sub SetLastError Lib "kernel32" Alias "SetLastError" (ByVal dwErrCode As Long)

DECLARE FUNCTION WaitForSingleObject Lib "kernel32" Alias "WaitForSingleObject" (ByVal hHandle As Long, ByVal dwMilliseconds As Long) As Long


'Rusdate$=field$(FileRec.Date,"-",2)+"-"+field$(FileRec.Date,"-",1)+"-"+right$(field$(FileRec.Date,"-",3),2)

function GetRusdate as string
result=field$(Date$,"-",2)+"-"+field$(Date$,"-",1)+"-"+right$(field$(Date$,"-",3),2)
end function

function Rusdate as string
result=field$(Date$,"-",2)+"-"+field$(Date$,"-",1)+"-"+right$(field$(Date$,"-",3),2)
end function

function Rudate as string
result=field$(Date$,"-",2)+"-"+field$(Date$,"-",1)+"-"+right$(field$(Date$,"-",3),2)
end function

'$include "C:\BAS\RAPIDQ\inc\conversion.inc"
$include "conversion.inc"
$include "Files.inc" 
'$include "Fileops.inc"
$include "func_array.inc" 
$include "parse.inc"   

$include "fbscancodes.inc"
$include "eml.inc"

'*****************************************
sub cprint(s as string)
dim sn as string
sn=s
chartooem sn,sn
print sn
End sub


'*****************************************
Function ODD(value AS INTEGER ) AS INTEGER
IF FRAC( value / 2 ) <> 0 THEN
	ODD = 1
ELSE  
	ODD = 0 
END IF 
End Function


'*****************************************
Sub ClearGrid(Sender As QStringGrid)
OldColcount=Sender.colcount
OldRowcount=Sender.rowcount

FixedColcount=Sender.FixedCols
FixedRowcount=Sender.FixedRows


'Sender.Col = Sender.FixedCols+1
'Sender.Row =Sender.FixedRows+ 1
'Sender.LeftCol = Sender.FixedCols+1
'Sender.TopRow =Sender.FixedRows+ 1

Sender.Col = 1
Sender.Row = 1
Sender.LeftCol = 1
Sender.TopRow = 1


Z = Sender.RowCount-2
For Y = Z To 1 Step -1
	Sender.DeleteRow(Y)
Next Y

Z = Sender.ColCount-2
For X = Z To 1 Step -1
	Sender.DeleteCol(X)
Next X

Sender.colcount=OldColcount
Sender.rowcount=OldRowcount

Sender.FixedCols=FixedColcount
Sender.FixedRows=FixedRowcount


End Sub


' enable / disable mouse and keyboard input to a specified window or control.fEnable = enable/disable flag
DECLARE FUNCTION EnableWindow Lib "user32" Alias "EnableWindow" (ByVal hwnd AS LONG, ByVal fEnable AS LONG) AS LONG  'If window was previously disabled, the return value is nonzero



'====================================================================================================================
'------- QDebug object , useful for debugging in loops  --------------
' JohnK, 12/2004
'Adapted from code by Pete Kleinschmidt and Michael Zito 1-5-2004, and Andrew Shelkovenko
' Method "Bug" left in
'======================================================================================================================
                                                                  'If window was not previously disabled, the return value is 0

TYPE QDebug EXTENDS QObject      'Begin defining our QDebug object
  PRIVATE:
     RowNum     AS INTEGER
     Redit      AS QRICHEDIT

  PUBLIC:
     Visible    AS LONG  PROPERTY SET Set_Visible
     Enabled    AS LONG  PROPERTY SET Set_Enabled
     Form       AS QFORM            'Create our Debug form
     TestSockets AS INTEGER         'also use WSAGetLastError


 PROPERTY SET Set_Visible(VisibleValue AS LONG)   'Property Set for Visible property
       IF VisibleValue = 1 THEN                    'If Visible property is set to True
            THIS.Form.Show                         'Then show our Debug window
            THIS.Redit.Parent = THIS.Form
            EnableWindow(THIS.Form.Handle, THIS.Enabled)
         ELSE                                      'Otherwise
            ' EnableWindow(THIS.Form.Handle, 1)
            THIS.Form.Close                        'Close the Debug window if it is open
        END IF
 END PROPERTY

 PROPERTY SET Set_Enabled(EnabledValue AS LONG)   '0 =  fixed/read-only, 1 = Debug window to move/close etc.
      THIS.Enabled = EnabledValue
      IF THIS.Form.Visible THEN EnableWindow(THIS.Form.Handle, THIS.Enabled)
 END PROPERTY
  
 SUB PrintWrap (StringToPrint AS STRING)             'wrap around text in form
      DIM RowHeight AS INTEGER
      DIM NewStr   AS STRING

      IF QDebug.Visible = 1 THEN                      'If Debug Visible property is True
           IF THIS.Form.Visible = 0 THEN THIS.Form.Show
           IF THIS.Redit.Visible THEN THIS.Redit.Visible= 0  'Print onto Form instead
           NewStr = StringToPrint + SPACE$(THIS.Form.ClientWidth)  'Clear out previous
           RowHeight = THIS.Form.TextHeight(NewStr)
           INC(THIS.RowNum, RowHeight)
           IF THIS.RowNum> (THIS.Form.ClientHeight - RowHeight) THEN THIS.RowNum = 0
           THIS.Form.TextOut(0, THIS.RowNum, NewStr, 0, &HFFFFFF)
           EnableWindow(THIS.Form.Handle, THIS.Enabled)
           DOEVENTS                                      'in case inside a loop
      END IF
 END SUB

 SUB PrintStr(StringToPrint AS STRING)                   'Debug Str Print method
  IF QDebug.Visible = 1 THEN                             'If Debug Visible property is True
       IF THIS.Form.Visible = 0 THEN
            THIS.Form.Show                               'turn it on
            THIS.Redit.Parent = THIS.Form                'need to set parent
            THIS.Redit.Visible = 1  'Turn it back on
            THIS.Redit.Height  = THIS.Form.ClientHeight  'always resize
            THIS.Redit.Width   = THIS.Form.ClientWidth
       END IF
       THIS.Redit.AddStrings(StringToPrint)             'Add the value to our Richedit box
       THIS.Redit.SelStart=LEN(THIS.Redit.Text)         'Move the cursor to the last character in the RichEdit box
       'send message to richedit control to scroll so cursor is in view (&HB7 = EM_SCROLLCARET)
       SENDMESSAGE(THIS.Redit.handle, &HB7, 0, 0)
       EnableWindow(THIS.Form.Handle, THIS.Enabled) 'enable mouse and keyboard input to the Debug form.
       DOEVENTS                                          'Let Windows do stuff
  END IF
 END SUB

 SUBI Print(...)
      DIM TheWholeStr AS STRING
      DIM i AS INTEGER
      DIM j AS INTEGER
    
      TheWholeStr = ""
      j = ParamStrCount
      IF ParamValCount > ParamStrCount THEN j = ParamValCount 'more strings or variables?
      FOR i = 1 TO j
           IF i<= ParamStrCount THEN TheWholeStr = TheWholeStr + ParamStr$(i) + " "
           IF i<= ParamValCount THEN TheWholeStr = TheWholeStr + STR$(ParamVal(i)) + " "
      NEXT i
      THIS.PrintStr(TheWholeStr)
 END SUBI


 SUB Bug (StringToPrint AS STRING)  'keep compatible with previous release
     THIS.PrintStr(StringToPrint)
 END SUB

 SUB SetError(NewErr AS LONG)
     SetLastError(NewErr)
 END SUB
 
 FUNCTION ErrNum() AS DWORD    'get windows last error
      DIM Rtn AS DWORD
    
      IF THIS.TestSockets THEN
          Rtn = WSAGetLastError
      ELSE
           Rtn = GetLastError()
      END IF
      THIS.Print(Rtn)
      RESULT = Rtn
 END FUNCTION


 FUNCTION Err$   AS STRING   'ripped off from format message
       DIM Buffer        AS STRING
       DIM lngRet        AS LONG

       Buffer=SPACE$(512)
       lngRet=FormatMessage (FORMAT_MESSAGE_FROM_SYSTEM, _
        0&, _
        GetLastError(), _
        LANG_NEUTRAL, _
        @Buffer, _
        LEN(Buffer), _
        0&)
      THIS.Print(LEFT$(Buffer,lngRet))  
      RESULT = LEFT$(Buffer,lngRet)
  END FUNCTION


   CONSTRUCTOR
      RowNum = 0
      Visible = 1             'Default to Visible
      Enabled = 1    'User wants to scroll/close/etc.
      Form.AutoScroll = 1
      Form.Height = 600
      Form.Width = 180
      Form.Caption = "Debug"
      Redit.Scrollbars = 2 'ssVertical = 2, ssBoth = 3
      TestSockets = 0   'no testing of Win Sockets
      SetError(0&)   'clear out previous error
 END CONSTRUCTOR
END TYPE


brem 1
'=========================================================== mouse wheel =======================
'const WM_USER = &H400

const    EM_AUTOURLDETECT            =WM_USER + 91

const    EM_CONVPOSITION             =WM_USER + 108
const    EM_SETLANGOPTIONS           =WM_USER + 120
const    EM_GETLANGOPTIONS           =WM_USER + 121
const    EM_GETIMECOMPMODE           =WM_USER + 122
const    EM_FINDTEXTW                =WM_USER + 123
const    EM_FINDTEXTEXW              =WM_USER + 124
const    EM_RECONVERSION             =WM_USER + 125
const    EM_SETIMEMODEBIAS           =WM_USER + 126  
const    EM_GETIMEMODEBIAS           =WM_USER + 127
const    EM_SETBIDIOPTIONS           =WM_USER + 200
const    EM_GETBIDIOPTIONS           =WM_USER + 201
const    EM_SETTYPOGRAPHYOPTIONS     =WM_USER + 202
const    EM_GETTYPOGRAPHYOPTIONS     =WM_USER + 203
const    EM_SETEDITSTYLE             =WM_USER + 204
const    EM_GETEDITSTYLE             =WM_USER + 205

const  WM_INPUTLANGCHANGEREQUEST=       &h0050
const  WM_INPUTLANGCHANGE  =            &h0051


const EM_CANPASTE = 1074
const EM_CANUNDO = 198
const EM_CHARFROMPOS = 215
const EM_DISPLAYBAND = 1075
const EM_EMPTYUNDOBUFFER = 205
const EM_EXGETSEL = 1076
const EM_EXLIMITTEXT = 1077
const EM_EXLINEFROMCHAR = 1078
const EM_EXSETSEL = 1079
const EM_FINDTEXT = 1080
const EM_FINDTEXTEX = 1103
const EM_FINDWORDBREAK = 1100
const EM_FMTLINES = 200
const EM_FORMATRANGE = 1081
const EM_GETCHARFORMAT = 1082
const EM_GETEVENTMASK = 1083
const EM_GETFIRSTVISIBLELINE = 206
const EM_GETHANDLE = 189
const EM_GETLIMITTEXT = 213
const EM_GETLINE = 196
const EM_GETLINECOUNT = 186
const EM_GETMARGINS = 212
const EM_GETMODIFY = 184
const EM_GETIMECOLOR = 1129
const EM_GETIMEOPTIONS = 1131
const EM_GETOPTIONS = 1102
const EM_GETOLEINTERFACE = 1084
const EM_GETPARAFORMAT = 1085
const EM_GETPASSWORDCHAR = 210
const EM_GETPUNCTUATION = 1125
const EM_GETRECT = 178
const EM_GETSEL = 176
const EM_GETSELTEXT = 1086
const EM_GETTEXTRANGE = 1099
const EM_GETTHUMB = 190
const EM_GETWORDBREAKPROC = 209
const EM_GETWORDBREAKPROCEX = 1104
const EM_GETWORDWRAPMODE = 1127
const EM_HIDESELECTION = 1087
const EM_LIMITTEXT = 197
const EM_LINEFROMCHAR = 201
const EM_LINEINDEX = 187
const EM_LINELENGTH = 193
const EM_LINESCROLL = 182
const EM_PASTESPECIAL = 1088
const EM_POSFROMCHAR = 214
const EM_REPLACESEL = 194
const EM_REQUESTRESIZE = 1089
const EM_SCROLL = 181
const EM_SCROLLCARET = 183
const EM_SELECTIONTYPE = 1090
const EM_SETBKGNDCOLOR = 1091
const EM_SETCHARFORMAT = 1092
const EM_SETEVENTMASK = 1093
const EM_SETHANDLE = 188
const EM_SETIMECOLOR = 1128
const EM_SETIMEOPTIONS = 1130
const EM_SETLIMITTEXT = 197
const EM_SETMARGINS = 211
const EM_SETMODIFY = 185
const EM_SETOLECALLBACK = 1094
const EM_SETOPTIONS = 1101
const EM_SETPARAFORMAT = 1095
const EM_SETPASSWORDCHAR = 204
const EM_SETPUNCTUATION = 1124
const EM_SETREADONLY = 207
const EM_SETRECT = 179
const EM_SETRECTNP = 180
const EM_SETSEL = 177
const EM_SETTABSTOPS = 203
const EM_SETTARGETDEVICE = 1096
const EM_SETWORDBREAKPROC = 208
const EM_SETWORDBREAKPROCEX = 1105
const EM_SETWORDWRAPMODE = 1126
const EM_STREAMIN = 1097
const EM_STREAMOUT = 1098
const EM_UNDO = 199


Const WM_MOUSEMOVE = &H200
Const WM_LBUTTONDOWN = &H201
Const WM_LBUTTONUP = &H202
Const WM_LBUTTONDBLCLK = &H203
Const WM_RBUTTONDOWN = &H204
Const WM_RBUTTONUP = &H205
Const WM_RBUTTONDBLCLK = &H206
Const WM_MBUTTONDOWN = &H207
Const WM_MBUTTONUP = &H208
Const WM_MBUTTONDBLCLK = &H209
Const WM_MOUSEWHEEL = &H20A
Const WM_KEYDOWN = &H100
Const WM_KEYUP = &H101

CONST GWL_WNDPROC = (-4)
CONST GWL_HWNDPARENT = (-8)

erem

'--- Declarations ---
DECLARE FUNCTION SetWindowLongAPI LIB "user32" ALIAS "SetWindowLongA" _
(ByVal hWnd AS LONG, ByVal nIndex AS LONG, ByVal dwNewLong AS LONG) AS LONG

Declare Function CallWindowProc Lib "user32" Alias "CallWindowProcA" _
(lpPrevWndFunc As Long,  hWnd As Long, Msg As Long,  wParam As Long,  lParam As Long) As Long

