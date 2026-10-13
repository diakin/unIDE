$IFNDEF __COMMON_INC   ' IncManager: include guard
$DEFINE __COMMON_INC
'RegEx to search for SUBs and FUNCTIONs in editor searches
'^[ \t]*(public |private |friend )?(sub|function|property|class)[ \t].*

'----- Compiler Directives
$TYPECHECK ON

'----- Code modules
'$INCLUDE "RapidQ.inc"
'$INCLUDE "Files.inc"

'----- Win API Function Declarations
DECLARE FUNCTION GetFocus LIB "user32" ALIAS "GetFocus"() AS LONG
DECLARE FUNCTION Setfocus LIB "user32" ALIAS "SetFocus"(hwnd AS LONG) AS LONG
DECLARE FUNCTION SendMessageA Lib "user32" Alias "SendMessageA" _
                 (hwnd As Long, wMsg As Long, wParam As Long, pf as Long) As Long
DECLARE FUNCTION SetWindowLong LIB "user32" ALIAS "SetWindowLongA"_
                 (hwnd AS LONG, nIndex AS LONG, dwNewLong AS LONG) AS LONG

'----- SUBs
SUB MinSet (frmHandle as integer, appHandle as integer)
  'Minimize to task bar. Jacques Philippe merci!
  'SAMPLE CALL: MinSet(frmMain.Handle, Application.Handle)
  SetWindowLong(frmHandle, -8, 0)
  SetWindowLong(appHandle, -8, frmHandle)
END SUB

'----- Constants
$IFNDEF TRUE
  $DEFINE TRUE 1
$ENDIF
$IFNDEF FALSE
  $DEFINE FALSE 0
$ENDIF

'----- Globals
DIM AppStart AS BYTE: AppStart = TRUE
    'Prevents intial resize exception in Win 2000
    'Add this as 1st line of frmResize Event SUB: 
    '--->IF AppStart = TRUE THEN AppStart = FALSE : EXIT SUB    
$ENDIF   ' IncManager: __COMMON_INC
