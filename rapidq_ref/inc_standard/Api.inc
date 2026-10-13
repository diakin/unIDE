$IFNDEF __API_INC   ' IncManager: include guard
$DEFINE __API_INC
const GWL_WNDPROC = -4

const ODT_MENU = 1

const ODS_SELECTED = 1
const ODS_GRAYED = 2
const ODS_DISABLED = 4
const ODS_CHECKED = 8
const ODS_FOCUS = &H10
const ODS_DEFAULT = &H20
const ODS_COMBOBOXEDIT = &H1000

const WM_DRAWITEM = &H2B
const WM_MEASUREITEM = &H2C
const WM_MENUSELECT = &H11F

const MF_BYCOMMAND = 0
const MF_BYPOSITION = &H400
const MF_OWNERDRAW = &H100
const MF_STRING = 0
const MF_BITMAP = 4
const MF_HILITE = &H80

const MIIM_STATE = &H1
const MIIM_ID = &H2
const MIIM_SUBMENU = &H4
const MIIM_CHECKMARKS = &H8
const MIIM_DATA = &H20
const MIIM_TYPE = &H10

const MFT_BITMAP = &H4
const MFT_MENUBARBREAK = &H20
Const MFT_MENUBREAK = &H40
Const MFT_OWNERDRAW = &H100
Const MFT_RADIOCHECK = &H200
Const MFT_RIGHTJUSTIFY = &H4000
Const MFT_RIGHTORDER = &H2000
Const MFT_SEPARATOR = &H800
Const MFT_STRING = &H0
Const MFS_CHECKED = &H8
Const MFS_DEFAULT = &H1000
Const MFS_DISABLED = &H2
Const MFS_ENABLED = &H0
Const MFS_GRAYED = &H1
Const MFS_HILITE = &H80
Const MFS_UNCHECKED = &H0
Const MFS_UNHILITE = &H0

TYPE TMEASUREITEMSTRUCT
    CtlType AS LONG
    CtlID AS LONG
    itemID AS LONG
    itemWidth AS LONG
    itemHeight AS LONG
    itemData AS DWORD
END TYPE

TYPE TDRAWITEMSTRUCT
    CtlType AS LONG
    CtlID AS LONG
    itemID AS LONG
    itemAction AS LONG
    itemState AS LONG
    hwndItem AS LONG
    hDC AS LONG
    left AS LONG
    top AS LONG
    right AS LONG
    bottom AS LONG
    itemData AS DWORD
END TYPE

Type MENUITEMINFO
	cbSize As Long
	fMask As Long
	fType As Long
	fState As Long
	wID As Long
	hSubMenu As Long
	hbmpChecked As Long
	hbmpUnchecked As Long
	dwItemData As Long
	dwTypeData As long
	cch As Long
End Type

DIM MeasureItem As TMEASUREITEMSTRUCT
DIM DrawItem As TDRAWITEMSTRUCT
DIM mii As  MENUITEMINFO
DIM Mem AS QMEMORYSTREAM


'---------------API Callback functions-----------------------------------
Declare Function SetWindowLong Lib "user32.dll" Alias "SetWindowLongA" _
(hwnd As Long, nIndex As Long, dwNewLong As Long) As Long

Declare Function CallWindowProc Lib "user32.dll" Alias "CallWindowProcA" _
(lpPrevWndFunc As Long, hwnd As Long, Msg As Long, wParam As Long, lParam As Long) As Long

Declare Function WindowProc(hwnd As Long, uMsg As Long, wParam As Long, lParam As Long) As Long
'------------------------------------------------------------------------

'-------------API Menu Functions-----------------------------------------
Declare Function GetMenu Lib "user32" Alias "GetMenu" (hWnd as Long) As Long
Declare Function GetMenuItemInfo Lib "user32.dll" Alias "GetMenuItemInfoA" _
(ByVal hMenu As Long, ByVal uItem As Long, ByVal fByPosition As Long, _
lpmii As MENUITEMINFO) As Long

Declare Function SetMenuItemInfo Lib "user32.dll" Alias "SetMenuItemInfoA" _
(ByVal hMenu As Long, ByVal uItem As Long, ByVal fByPosition As Long, _
lpmii As MENUITEMINFO) As Long

Declare Function InsertMenuItem Lib "user32.dll" Alias "InsertMenuItemA" _
(ByVal hMenu As Long, ByVal uItem As Long, ByVal fByPosition As Long, _
lpmii As MENUITEMINFO) As Long
'------------------------------------------------------------------------
  
$ENDIF   ' IncManager: __API_INC
