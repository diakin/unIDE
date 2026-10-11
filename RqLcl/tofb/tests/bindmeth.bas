$APPTYPE CONSOLE
' BIND This.Method + SetNewCallBack_4 + SetWindowLong inside a TYPE
' (rapidq2.inc QFormEx.GrabWindowProc): two objects subclass two windows,
' each window's messages go to its own object
$INCLUDE "../../../rapidq_ref/incOld/CallBack_4.Inc"
DECLARE FUNCTION CreateWindowEx LIB "user32" ALIAS "CreateWindowExA" (dwExStyle AS LONG, lpClassName AS STRING, lpWindowName AS STRING, dwStyle AS LONG, x AS LONG, y AS LONG, nWidth AS LONG, nHeight AS LONG, hWndParent AS LONG, hMenu AS LONG, hInstance AS LONG, lpParam AS LONG) AS LONG
DECLARE FUNCTION SetWindowLong LIB "user32" ALIAS "SetWindowLongA" (hWnd AS LONG, nIndex AS LONG, dwNewLong AS LONG) AS LONG
DECLARE FUNCTION CallWindowProc LIB "user32" ALIAS "CallWindowProcA" (lpPrevWndFunc AS LONG, hWnd AS LONG, Msg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
DECLARE FUNCTION SendMessage LIB "user32" ALIAS "SendMessageA" (hWnd AS LONG, Msg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
CONST GWL_WNDPROC = -4
CONST WM_USER = &H400

TYPE QSUBWIN EXTENDS QOBJECT
  Handle AS LONG
  BindIndex AS LONG
  MyWndProc AS LONG
  pOldProc AS LONG
  Hits AS LONG
  Tag AS STRING

  FUNCTION WindowProc(hWnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
    IF uMsg = WM_USER + 1 THEN
      QSUBWIN.Hits = QSUBWIN.Hits + wParam
      Result = QSUBWIN.Hits
    ELSE
      Result = CallWindowProc(QSUBWIN.pOldProc, hWnd, uMsg, wParam, lParam)
    END IF
  END FUNCTION

  SUB Grab
    QSUBWIN.Handle = CreateWindowEx(0, "STATIC", QSUBWIN.Tag, 0, 0, 0, 10, 10, 0, 0, 0, 0)
    BIND QSUBWIN.BindIndex TO QSUBWIN.WindowProc
    QSUBWIN.MyWndProc = SetNewCallBack_4(QSUBWIN.BindIndex)
    QSUBWIN.pOldProc = SetWindowLong(QSUBWIN.Handle, GWL_WNDPROC, QSUBWIN.MyWndProc)
  END SUB
END TYPE

DIM WinA AS QSUBWIN
DIM WinB AS QSUBWIN
WinA.Tag = "A"
WinB.Tag = "B"
WinA.Grab
WinB.Grab
PRINT "windows "; (WinA.Handle <> 0); (WinB.Handle <> 0)
PRINT "A send "; SendMessage(WinA.Handle, WM_USER + 1, 3, 0)
PRINT "B send "; SendMessage(WinB.Handle, WM_USER + 1, 10, 0)
PRINT "A send "; SendMessage(WinA.Handle, WM_USER + 1, 4, 0)
PRINT "A hits "; WinA.Hits
PRINT "B hits "; WinB.Hits
