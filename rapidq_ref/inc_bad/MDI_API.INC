TYPE WNDCLASSEX
    cbSize AS LONG
    style AS LONG
    lpfnWndProc AS LONG
    cbClsExtra AS LONG
    cbWndExtra AS LONG
    hInstance AS LONG
    hIcon AS LONG
    hCursor AS LONG
    hbrBackground AS LONG
    lpszMenuName AS LONG
    lpszClassName AS LONG
    hIconSm AS LONG
END TYPE

DECLARE FUNCTION RegisterClassEx LIB "User32" ALIAS "RegisterClassExA" _
                 (pcWndClassEx AS WNDCLASSEX) AS LONG
DECLARE FUNCTION EnumChildWindows LIB "User32" ALIAS "EnumChildWindows" _
                 (hWndParent AS LONG, lpEnumFunc AS LONG, lParam AS LONG) AS LONG
DECLARE FUNCTION CreateWindowEx LIB "User32" ALIAS "CreateWindowExA" _
                 (dwExStyle AS LONG, lpClassName AS STRING, lpWindowName AS STRING, _
                  dwStyle AS LONG, x AS LONG, y AS LONG, nWidth AS LONG, nHeight AS LONG, _
                  hWndParent AS LONG, hMenu AS LONG, hInstance AS LONG, lpParam AS LONG) AS LONG
DECLARE FUNCTION DefMDIChildProc LIB "User32" ALIAS "DefMDIChildProcA" _
                 (hWnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
DECLARE FUNCTION GetClassName LIB "User32" ALIAS "GetClassNameA" _
                 (hwnd AS LONG, lpClassName AS STRING, nMaxCount AS LONG) AS LONG
DECLARE FUNCTION ReadFile LIB "Kernel32" ALIAS "ReadFile" _
                 (hFile AS LONG, lpBuffer AS LONG, nNumberOfBytesToRead AS LONG, _
                  lpNumberOfBytesRead AS LONG, lpOverlapped AS LONG) AS LONG
DECLARE FUNCTION CreateFile LIB "Kernel32" ALIAS "CreateFileA" _
                 (lpFileName AS STRING, dwDesiredAccess AS LONG, dwShareMode AS LONG, _
                  lpSecurityAttributes AS LONG, dwCreationDisposition AS LONG, _
                  dwFlagsAndAttributes AS LONG, hTemplateFile AS LONG) AS LONG
DECLARE FUNCTION SetProp LIB "User32" ALIAS "SetPropA" _
                 (hwnd AS LONG, lpString AS STRING, hData AS LONG) AS LONG
DECLARE FUNCTION GetProp LIB "User32"  ALIAS "GetPropA" _
                 (hwnd AS LONG, lpString AS STRING) AS LONG
DECLARE FUNCTION GetClientRect LIB "User32" ALIAS "GetClientRect" _
                 (hwnd AS LONG, lpRect AS QRECT) AS LONG
DECLARE FUNCTION MoveWindow LIB "User32" ALIAS "MoveWindow" _
                 (hwnd AS LONG, x AS LONG, y AS LONG, nWidth AS LONG, nHeight AS LONG, bRepaint AS LONG) AS LONG
DECLARE FUNCTION SetWindowLong1 LIB "User32" ALIAS "SetWindowLongA" _
                 (hwnd AS LONG, nIndex AS LONG, dwNewLong AS LONG) AS LONG
DECLARE FUNCTION GetWindowText LIB "User32" ALIAS "GetWindowTextA" _
                 (hwnd AS LONG, lpString AS STRING, cch AS LONG) AS LONG
DECLARE FUNCTION SetFocus LIB "User32" ALIAS "SetFocus" _
                 (hwnd AS LONG) AS LONG
'DECLARE FUNCTION CloseHandle LIB "Kernel32" ALIAS "CloseHandle" (hObject AS LONG) AS LONG

const WS_EX_MDICHILD = &H40
const WS_EX_CLIENTEDGE = &H200
const WS_CHILD = &H40000000
const WS_VISIBLE = &H10000000
const WS_OVERLAPPED = &H0
const WS_CAPTION = &HC00000
const WS_SYSMENU = &H80000
const WS_THICKFRAME = &H40000
const WS_MINIMIZEBOX = &H20000
const WS_MAXIMIZEBOX = &H10000
const WS_VSCROLL = &H200000
const WS_HSCROLL = &H100000
const WS_OVERLAPPEDWINDOW = (WS_OVERLAPPED OR WS_CAPTION OR WS_SYSMENU OR WS_THICKFRAME OR WS_MINIMIZEBOX OR WS_MAXIMIZEBOX)

const CW_USEDEFAULT = &H80000000

const WM_CREATE = &H1
const WM_DESTROY = &H2
const WM_SIZE = &H5
const WM_SETTEXT = &HC
const WM_SYSCOMMAND = &H112
const WM_MDIDESTROY = &H221
const WM_MDIRESTORE = &H223
const WM_MDIMAXIMIZE = &H225
const WM_MDITILE = &H226
const WM_MDICASCADE = &H227
const WM_MDIICONARRANGE = &H228
const WM_MDIACTIVATE = &H222
const WM_MDISETMENU = &H230
const ES_AUTOVSCROLL = &H40
const ES_AUTOHSCROLL = &H80
const ES_MULTILINE = &H4

const MDITILE_VERTICAL = &H0
const MDITILE_HORIZONTAL = &H1

const SC_MINIMIZE = &HF020

const GENERIC_READ = &H80000000
const OPEN_ALWAYS = 4
const FILE_SHARE_READ = &H1
const FILE_ATTRIBUTE_NORMAL = &H80
const SIZE_RESTORED = 0
const SIZE_MAXIMIZED = 2

const GWL_HWNDPARENT = (-8)
const GWL_EXSTYLE = (-20)  