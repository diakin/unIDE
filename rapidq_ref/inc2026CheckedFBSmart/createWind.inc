'=======================================================

DECLARE FUNCTION LoadLibrary LIB "KERNEL32" ALIAS "LoadLibraryA" _
                 (LibFileName AS STRING) AS LONG
DECLARE FUNCTION FreeLibrary LIB "KERNEL32" ALIAS "FreeLibrary" _
                 (hInst AS LONG) AS LONG

DECLARE FUNCTION CreateWindowEx LIB "USER32" ALIAS "CreateWindowExA" _
                 (ExStyle&, ClassName$, WindowName$, Style&, X&, Y&, _
                  Width&, Height&, WndParent&, hMenu&, hInstance&, Param&) AS LONG

dim hInst AS LONG

$DEFINE HWND INTEGER

const WS_EX_CLIENTEDGE = &H200 ' Just some of the many API constants
const WS_CHILD = &H40000000
const WS_VISIBLE = &H10000000
const WS_BORDER = &H800000
const ES_LEFT = 0
const ES_AUTOHSCROLL = &H80
const ES_MULTILINE = &H4

const WM_COMMAND = &H111

DECLARE FUNCTION GetModuleHandle LIB "KERNEL32" ALIAS "GetModuleHandleA" _
(ModuleName AS STRING) AS LONG

DECLARE FUNCTION SetWindowText LIB "USER32" ALIAS "SetWindowTextA" _
(Hwnd AS INTEGER, Text AS STRING) AS LONG

DECLARE SUB FormWndProc (Handle AS INTEGER, uMsg AS LONG, wParam AS LONG,lParam AS LONG)

  