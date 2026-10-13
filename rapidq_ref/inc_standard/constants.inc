$IFNDEF __CONSTANTS_INC   ' IncManager: include guard
$DEFINE __CONSTANTS_INC

' Color Types
Public Const CTLCOLOR_MSGBOX = 0
Public Const CTLCOLOR_EDIT = 1
Public Const CTLCOLOR_LISTBOX = 2
Public Const CTLCOLOR_BTN = 3
Public Const CTLCOLOR_DLG = 4
Public Const CTLCOLOR_SCROLLBAR = 5
Public Const CTLCOLOR_STATIC = 6
Public Const CTLCOLOR_MAX = 8   '  three bits max

Public Const COLOR_SCROLLBAR = 0
Public Const COLOR_BACKGROUND = 1
Public Const COLOR_ACTIVECAPTION = 2
Public Const COLOR_INACTIVECAPTION = 3
Public Const COLOR_MENU = 4
Public Const COLOR_WINDOW = 5
Public Const COLOR_WINDOWFRAME = 6
Public Const COLOR_MENUTEXT = 7
Public Const COLOR_WINDOWTEXT = 8
Public Const COLOR_CAPTIONTEXT = 9
Public Const COLOR_ACTIVEBORDER = 10
Public Const COLOR_INACTIVEBORDER = 11
Public Const COLOR_APPWORKSPACE = 12
Public Const COLOR_HIGHLIGHT = 13
Public Const COLOR_HIGHLIGHTTEXT = 14
Public Const COLOR_BTNFACE = 15
Public Const COLOR_BTNSHADOW = 16
Public Const COLOR_GRAYTEXT = 17
Public Const COLOR_BTNTEXT = 18
Public Const COLOR_INACTIVECAPTIONTEXT = 19
Public Const COLOR_BTNHIGHLIGHT = 20

Declare Function GetSysColor1 Lib "user32" Alias "GetSysColor" (ByVal nIndex As Long) As Long
Declare Function SetSysColors1 Lib "user32" Alias "SetSysColors" (ByVal nChanges As Long, lpSysColor As Long, lpColorValues As Long) As Long


const WM_USER = &H400

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
'Const WM_KEYDOWN = &H100
Const WM_KEYUP = &H101




'___________________________________________
const WM_CUT = 768
const WM_COPY = 769
const WM_COPYDATA = 74
const WM_PASTE = 770
const WM_CLEAR = 771
const WM_CHAR = 258

'------------- /* Extended edit style masks */
const SES_EMULATESYSEDIT  =1
const SES_BEEPONMAXTEXT   =2
const SES_EXTENDBACKCOLOR  =4
const SES_MAPCPS    =8
const SES_EMULATE10    =16
const SES_USECRLF    =32
const SES_USEAIMM    =64
const SES_NOIME     =128

const SES_ALLOWBEEPS   =256
const SES_UPPERCASE    =512
const SES_LOWERCASE   =1024
const SES_NOINPUTSEQUENCECHK =2048
const SES_BIDI     =4096
const SES_SCROLLONKILLFOCUS  =8192
const SES_XLTCRCRLFTOCR  =16384


'-------- /* Options for EM_SETLANGOPTIONS and EM_GETLANGOPTIONS */

const IMF_AUTOKEYBOARD  = &h0001
const IMF_AUTOFONT   = &h0002
const IMF_IMECANCELCOMPLETE = &h0004 ' // high completes comp string when aborting, low cancels.
const IMF_IMEALWAYSSENDNOTIFY = &h0008
const IMF_AUTOFONTSIZEADJUST = &h0010
const IMF_UIFONTS    = &h0020
const IMF_DUALFONT   = &h0080


TYPE  PARAFORMAT 
cbSize             AS  DWORD             
dwMask             AS  DWORD             
wNumbering         AS  WORD                  
wEffects           AS  WORD                  
dxStartIndent      AS  DWORD             
dxRightIndent      AS  DWORD             
dxOffset           AS  DWORD             
wAlignment         AS  WORD                  
cTabCount          AS  WORD                  
rgxTabs            AS  DWORD      ''   MAX_TAB_STOPS dup()
END TYPE

const PFM_ALIGNMENT = &H8
const PFM_NUMBERING = &H20
const PFM_OFFSET = &H4
const PFM_OFFSETINDENT = &H80000000
const PFM_RIGHTINDENT = &H2
const PFM_STARTINDENT = &H1
const PFM_TABSTOPS = &H10
const PFA_CENTER = &H3
const PFA_LEFT = &H1
const PFA_RIGHT = &H2

const PFN_BULLET=&H1

type _paraformat '--Size is 156 bytes
cbSize as short
wPad1 as short
dwMask as dword
wNumbering as word
wReserved as word
dxStartIndent as Long
dxRightIndent as Long
dxOffset as Long
wAlignment as Word
cTabCount as Short '--Max Tab Stops=32
rgxTabs(31) as Long
end type


'*****************************************
sub SetPARAFORMAT (Sender as QRichedit)
Dim Mem as QMemoryStream
dim pf as _paraformat
Dim TabSpace as Long
Dim x as Long

Mem.Position=0
Mem.WriteUdt pf

pf.cbSize=Mem.Size
pf.dwMask=PFM_TABSTOPS 'or PFM_ALIGNMENT or PFM_STARTINDENT or PFM_OFFSET or PFM_RIGHTINDENT or PFM_NUMBERING

pf.cTabCount=8

'--The tab spaces are measured in twips. 1440 is roughly 1 inch
TabSpace=0.2*1440
For x=0 to 31
	pf.rgxTabs(x)=TabSpace*x
Next x

'//pf.dxStartIndent=Val(StartIndent.Text)*1440
'//pf.dxOffset=Val(OffsetIndent.Text)*1440
'//pf.dxRightIndent=Val(RightIndent.Text)*1440

'//if aLeft.Checked then pf.wAlignment=PFA_LEFT
'//if aCenter.Checked then pf.wAlignment=PFA_CENTER
'//if aRight.Checked then pf.wAlignment=PFA_RIGHT

'pf.wNumbering=aBullet.Checked*PFN_BULLET

Mem.Position=0
Mem.WriteUdt pf
SendMessageA(Sender.handle, EM_SETPARAFORMAT, 0, Mem.Pointer) 
Mem.Close
end sub

$ENDIF   ' IncManager: __CONSTANTS_INC
