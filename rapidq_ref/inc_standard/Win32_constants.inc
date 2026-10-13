$IFNDEF __WIN32_CONSTANTS_INC   ' IncManager: include guard
$DEFINE __WIN32_CONSTANTS_INC
'_______________________________________________________________________________
' Values for dwExStyle
'_______________________________________________________________________________
const  WS_EX_ACCEPTFILES = 16
const  WS_EX_APPWINDOW = &H40000
const  WS_EX_CLIENTEDGE = 512
const  WS_EX_CONTEXTHELP = &H400
const  WS_EX_CONTROLPARENT = &H10000
const  WS_EX_DLGMODALFRAME = 1
const  WS_EX_LEFT = 0
const  WS_EX_LEFTSCROLLBAR = &H4000
const  WS_EX_LTRREADING = 0
const  WS_EX_MDICHILD = 64
const  WS_EX_NOPARENTNOTIFY = 4
const  WS_EX_OVERLAPPEDWINDOW = &H300
const  WS_EX_PALETTEWINDOW = &H188
const  WS_EX_RIGHT = &H1000
const  WS_EX_RIGHTSCROLLBAR = 0
const  WS_EX_RTLREADING = &H2000
const  WS_EX_STATICEDGE = &H20000
const  WS_EX_TOOLWINDOW = 128
const  WS_EX_TOPMOST = 8
const  WS_EX_TRANSPARENT = 32
const  WS_EX_WINDOWEDGE = 256
const  WS_EX_LAYERED =  &H080000


'_______________________________________________________________________________
' Values for dwStyle
'_______________________________________________________________________________

' ---------------------------------------> Window Class
const  WS_BORDER = &H800000
const  WS_CAPTION = &Hc00000
const  WS_CHILD = &H40000000
const  WS_CHILDWINDOW = &H40000000
const  WS_CLIPCHILDREN = &H2000000
const  WS_CLIPSIBLINGS = &H4000000
const  WS_DISABLED = &H8000000
const  WS_DLGFRAME = &H400000
const  WS_GROUP = &H20000
const  WS_HSCROLL = &H100000
const  WS_ICONIC = &H20000000
const  WS_MAXIMIZE = &H1000000
const  WS_MAXIMIZEBOX = &H10000
const  WS_MINIMIZE = &H20000000
const  WS_MINIMIZEBOX = &H20000
const  WS_OVERLAPPED = 0
const  WS_OVERLAPPEDWINDOW = &Hcf0000
const  WS_POPUP = &H80000000
const  WS_POPUPWINDOW = &H80880000
const  WS_SIZEBOX = &H40000
const  WS_SYSMENU = &H80000
const  WS_TABSTOP = &H10000
const  WS_THICKFRAME = &H40000
const  WS_TILED = 0
const  WS_TILEDWINDOW = &Hcf0000
const  WS_VISIBLE = &H10000000
const  WS_VSCROLL = &H200000
const  MDIS_ALLCHILDSTYLES = 1

' ---------------------------------------> Button class
const  BS_3STATE = 5
const  BS_AUTO3STATE = 6
const  BS_AUTOCHECKBOX = 3
const  BS_AUTORADIOBUTTON = 9
const  BS_BITMAP = 128
const  BS_BOTTOM = &H800
const  BS_CENTER = &H300
const  BS_CHECKBOX = 2
const  BS_DEFPUSHBUTTON = 1
const  BS_GROUPBOX = 7
const  BS_ICON = 64
const  BS_LEFT = 256
const  BS_LEFTTEXT = 32
const  BS_MULTILINE = &H2000
const  BS_NOTIFY = &H4000
const  BS_OWNERDRAW = &Hb
const  BS_PUSHBUTTON = 0
const  BS_PUSHBOX = 10
const  BS_PUSHLIKE = 4096
const  BS_RADIOBUTTON = 4
const  BS_RIGHT = 512
const  BS_RIGHTBUTTON = 32
const  BS_TEXT = 0
const  BS_TOP = &H400
const  BS_USERBUTTON = 8
const  BS_VCENTER = &Hc00
const  BS_FLAT = &H8000

' ---------------------------------------> Combobox Class
const  CBS_AUTOHSCROLL = 64
const  CBS_DISABLENOSCROLL = &H800
const  CBS_DROPDOWN = 2
const  CBS_DROPDOWNLIST = 3
const  CBS_HASSTRINGS = 512
const  CBS_LOWERCASE = &H4000
const  CBS_NOINTEGRALHEIGHT = &H400
const  CBS_OEMCONVERT = 128
const  CBS_OWNERDRAWFIXED = 16
const  CBS_OWNERDRAWVARIABLE = 32
const  CBS_SIMPLE = 1
const  CBS_SORT = 256
const  CBS_UPPERCASE = &H2000

' ---------------------------------------> Edit Class
'                                          Qedit, QRichedit

const  ES_AUTOHSCROLL = 128
const  ES_AUTOVSCROLL = 64
const  ES_CENTER = 1
const  ES_LEFT = 0
const  ES_LOWERCASE = 16
const  ES_MULTILINE = 4
const  ES_NOHIDESEL = 256
const  ES_NUMBER = &H2000
const  ES_OEMCONVERT = &H400
const  ES_PASSWORD = 32
const  ES_READONLY = &H800
const  ES_RIGHT = 2
const  ES_UPPERCASE = 8
const  ES_WANTRETURN = 4096

' --------------------------------------->  Listbox Class
const  LBS_DISABLENOSCROLL = 4096
const  LBS_EXTENDEDSEL = &H800
const  LBS_HASSTRINGS = 64
const  LBS_MULTICOLUMN = 512
const  LBS_MULTIPLESEL = 8
const  LBS_NODATA = &H2000
const  LBS_NOINTEGRALHEIGHT = 256
const  LBS_NOREDRAW = 4
const  LBS_NOSEL = &H4000
const  LBS_NOTIFY = 1
const  LBS_OWNERDRAWFIXED = 16
const  LBS_OWNERDRAWVARIABLE = 32
const  LBS_SORT = 2
const  LBS_STANDARD = &Ha00003
const  LBS_USETABSTOPS = 128
const  LBS_WANTKEYBOARDINPUT = &H400

' ---------------------------------------> Scrollbar Class
const  SBS_BOTTOMALIGN = 4
const  SBS_HORZ = 0
const  SBS_LEFTALIGN = 2
const  SBS_RIGHTALIGN = 4
const  SBS_SIZEBOX = 8
const  SBS_SIZEBOXBOTTOMRIGHTALIGN = 4
const  SBS_SIZEBOXTOPLEFTALIGN = 2
const  SBS_SIZEGRIP = 16
const  SBS_TOPALIGN = 2
const  SBS_VERT = 1

' ---------------------------------------> Static Class
const  SS_BITMAP = &He
const  SS_BLACKFRAME = 7
const  SS_BLACKRECT = 4
const  SS_CENTER = 1
const  SS_CENTERIMAGE = 512
const  SS_ENHMETAFILE = &Hf
const  SS_ETCHEDFRAME = &H12
const  SS_ETCHEDHORZ = 16
const  SS_ETCHEDVERT = &H11
const  SS_GRAYFRAME = 8
const  SS_GRAYRECT = 5
const  SS_ICON = 3
const  SS_LEFT = 0
const  SS_LEFTNOWORDWRAP = &Hc
const  SS_NOPREFIX = 128
const  SS_NOTIFY = 256
const  SS_OWNERDRAW = &Hd
const  SS_REALSIZEIMAGE = &H800
const  SS_RIGHT = 2
const  SS_RIGHTJUST = &H400
const  SS_SIMPLE = 11
const  SS_SUNKEN = 4096
const  SS_WHITEFRAME = 9
const  SS_WHITERECT = 6
const  SS_USERITEM = 10

' ---------------------------------------> Dialog box styles
const  DS_3DLOOK = 4
const  DS_ABSALIGN = 1
const  DS_CENTER = &H800
const  DS_CENTERMOUSE = 4096
const  DS_CONTEXTHELP = &H2000
const  DS_CONTROL = &H400
const  DS_FIXEDSYS = 8
const  DS_LOCALEDIT = 32
const  DS_MODALFRAME = 128
const  DS_NOFAILCREATE = 16
const  DS_NOIDLEMSG = 256
const  DS_SETFONT = 64
const  DS_SETFOREGROUND = 512
const  DS_SYSMODAL = 2
'_______________________________________________________________________________
' "EXTENDED" Properties
'_______________________________________________________________________________

' ---------------------------------------> Button
const  BM_SETCHECK	= 241
const  BM_SETIMAGE	= 247
const  BM_SETSTATE	= 243
const  BM_SETSTYLE	= 244
' ---------------------------------------> ListBox
const LB_ADDFILE = 406
const LB_ADDSTRING = 384
const LB_DELETESTRING = 386
const LB_DIR = 397
const LB_FINDSTRING = 399
const LB_FINDSTRINGEXACT = 418
const LB_GETANCHORINDEX = 413
const LB_GETCARETINDEX = 415
const LB_GETCOUNT = 395
const LB_GETCURSEL = 392
const LB_GETHORIZONTALEXTENT = 403
const LB_GETITEMDATA = 409
const LB_GETITEMHEIGHT = 417
const LB_GETITEMRECT = 408
const LB_GETLOCALE = 422
const LB_GETSEL = 391
const LB_GETSELCOUNT = 400
const LB_GETSELITEMS = 401
const LB_GETTEXT = 393
const LB_GETTEXTLEN = 394
const LB_GETTOPINDEX = 398
const LB_INITSTORAGE = 424
const LB_INSERTSTRING = 385
const LB_ITEMFROMPOINT = 425
const LB_RESETCONTENT = 388
const LB_SELECTSTRING = 396
const LB_SELITEMRANGE = 411
const LB_SELITEMRANGEEX = 387
const LB_SETANCHORINDEX = 412
const LB_SETCARETINDEX = 414
const LB_SETCOLUMNWIDTH = 405
const LB_SETCOUNT = 423
const LB_SETCURSEL = 390
const LB_SETHORIZONTALEXTENT = 404
const LB_SETITEMDATA = 410
const LB_SETITEMHEIGHT = 416
const LB_SETLOCALE = 421
const LB_SETSEL = 389
const LB_SETTABSTOPS = 402
const LB_SETTOPINDEX = 407

' ---------------------------------------> FileListBox
const DDL_ARCHIVE = 32
const DDL_DIRECTORY = 16
const DDL_DRIVES = 16384
const DDL_EXCLUSIVE = 32768
const DDL_HIDDEN = 2
const DDL_READONLY = 1
const DDL_READWRITE = 0
const DDL_SYSTEM = 4
const DDL_POSTMSGS = 8192


' ---------------------------------------> Combobox
const CB_ADDSTRING = 323
const CB_DELETESTRING = 324
const CB_DIR = 325
const CB_FINDSTRING = 332
const CB_FINDSTRINGEXACT = 344
const CB_GETCOUNT = 326
const CB_GETCURSEL = 327
const CB_GETDROPPEDCONTROLRECT = 338
const CB_GETDROPPEDSTATE = 343
const CB_GETDROPPEDWIDTH = 351
const CB_GETEDITSEL = 320
const CB_GETEXTENDEDUI = 342
const CB_GETHORIZONTALEXTENT = 349
const CB_GETITEMDATA = 336
const CB_GETITEMHEIGHT = 340
const CB_GETLBTEXT = 328
const CB_GETLBTEXTLEN = 329
const CB_GETLOCALE = 346
const CB_GETTOPINDEX = 347
const CB_INITSTORAGE = 353
const CB_INSERTSTRING = 330
const CB_LIMITTEXT = 321
const CB_RESETCONTENT = 331
const CB_SELECTSTRING = 333
const CB_SETCURSEL = 334
const CB_SETDROPPEDWIDTH = 352
const CB_SETEDITSEL = 322
const CB_SETEXTENDEDUI = 341
const CB_SETHORIZONTALEXTENT = 350
const CB_SETITEMDATA = 337
const CB_SETITEMHEIGHT = 339
const CB_SETLOCALE = 345
const CB_SETTOPINDEX = 348
const CB_SHOWDROPDOWN = 335
const CBN_CLOSEUP = 8
const CBN_DBLCLK = 2
const CBN_DROPDOWN = 7
const CBN_EDITCHANGE = 5
const CBN_EDITUPDATE = 6
const CBN_ERRSPACE = (-1)
const CBN_KILLFOCUS = 4
const CBN_SELCHANGE = 1
const CBN_SELENDCANCEL = 10
const CBN_SELENDOK = 9
const CBN_SETFOCUS = 3


const WM_SETFONT = 48
Const WM_SETREDRAW = &HB

'_______________________________________________________________________________
' Other Stuff (I think, not needed at the moment
'_______________________________________________________________________________

'const WS_EX_CLIENTEDGE = &H200
'const WS_CHILD = &H40000000
'const WS_VISIBLE = &H10000000
'const WS_BORDER = &H800000
'const ES_LEFT = 0
'const ES_AUTOHSCROLL = &H80

const WM_COMMAND = &H111
Const WM_USER = &H400
Const WM_CLOSE = &H10
Const WM_SIZE = &H5

'** Some Button Notification Codes **

const BN_CLICKED = 0
const BN_PAINT = 1
const BN_HILITE = 2           '** Pushed   **
const BN_UNHILITE = 3         '** UnPushed **
const BM_DOUBLECLICKED = 4    '** There's more... **

const IDM_CLEAR = 1



  
$ENDIF   ' IncManager: __WIN32_CONSTANTS_INC
