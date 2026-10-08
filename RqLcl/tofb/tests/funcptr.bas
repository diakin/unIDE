$APPTYPE CONSOLE
' Function pointers (chapter 11, otherdetail.html): BIND, CALLFUNC,
' CODEPTR; window subclassing as in RQdebugger (NewWndProc.Inc:
' Bind + SetNewWndProc + CallWindowProc),
' (CallBack_4.Inc: SetNewCallBack_4 for SetTimer), CODEPTR for EnumChildWindows
$INCLUDE "../../../rapidq_ref/inc/CallBack_4.Inc"
$INCLUDE "../../../rapidq_ref/inc/NewWndProc.Inc"
DECLARE FUNCTION SendMessage LIB "user32" ALIAS "SendMessageA" (hWnd AS LONG, Msg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
DECLARE FUNCTION CallWindowProc LIB "user32" ALIAS "CallWindowProcA" (lpPrevWndFunc AS LONG, hWnd AS LONG, Msg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
DECLARE FUNCTION SetWindowLongAPI LIB "user32" ALIAS "SetWindowLongA" (hWnd AS LONG, nIndex AS LONG, dwNewLong AS LONG) AS LONG
DECLARE FUNCTION EnumChildWindows LIB "user32" ALIAS "EnumChildWindows" (hWndParent AS LONG, lpEnumFunc AS LONG, lParam AS LONG) AS LONG
DECLARE SUB Test1 (I AS INTEGER)
DECLARE SUB Test2 (I AS INTEGER)
DECLARE FUNCTION Twice (X AS LONG) AS LONG
DECLARE FUNCTION MyFuncTemp (X AS LONG) AS LONG
DECLARE FUNCTION EditWndProc (hWnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
DECLARE FUNCTION ListWndProc (hWnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
DECLARE FUNCTION EnumProc (hWnd AS LONG, lParam AS LONG) AS LONG
DECLARE SUB TimerProc (hWnd AS LONG, uMsg AS LONG, idEvent AS LONG, dwTime AS LONG)
DECLARE FUNCTION SetTimer LIB "user32" ALIAS "SetTimer" (hWnd AS LONG, nIDEvent AS LONG, uElapse AS LONG, lpTimerFunc AS LONG) AS LONG
DECLARE FUNCTION KillTimer LIB "user32" ALIAS "KillTimer" (hWnd AS LONG, nIDEvent AS LONG) AS LONG
CONST GWL_WNDPROC = -4
CONST WM_USER = &H400
DIM FPtr(1 TO 2) AS INTEGER
DIM Single1 AS INTEGER, Template AS INTEGER, FnPtr2 AS INTEGER
DIM OldEditProc AS LONG, OldListProc AS LONG, EditCount AS INTEGER, ListCount AS INTEGER
DIM ChildCount AS INTEGER, iTmpBind AS INTEGER, hTimer AS INTEGER, TimerCount AS INTEGER
CREATE Form AS QFORM
  CREATE Edit1 AS QEDIT
  END CREATE
  CREATE List1 AS QLISTBOX
    Top = 40
  END CREATE
  CREATE Button1 AS QBUTTON
    Top = 120
  END CREATE
END CREATE

SUB Test1 (I AS INTEGER)
  PRINT "test1 "; I
END SUB
SUB Test2 (I AS INTEGER)
  PRINT "test2 "; I * 2
END SUB
FUNCTION Twice (X AS LONG) AS LONG
  Twice = X * 2
END FUNCTION
FUNCTION EditWndProc (hWnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
  IF uMsg = WM_USER + 3 THEN EditCount = EditCount + wParam
  Result = CallWindowProc(OldEditProc, hWnd, uMsg, wParam, lParam)
END FUNCTION
FUNCTION ListWndProc (hWnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
  IF uMsg = WM_USER + 4 THEN ListCount = ListCount + 1
  Result = CallWindowProc(OldListProc, hWnd, uMsg, wParam, lParam)
END FUNCTION
SUB TimerProc (hWnd AS LONG, uMsg AS LONG, idEvent AS LONG, dwTime AS LONG)
  IF idEvent = 77 THEN TimerCount = TimerCount + 1
END SUB
FUNCTION EnumProc (hWnd AS LONG, lParam AS LONG) AS LONG
  ChildCount = ChildCount + lParam
  EnumProc = 1
END FUNCTION

' BIND / CALLFUNC (chapter 11)
BIND Single1 TO Test1
CALLFUNC(Single1, 120)
BIND FPtr(1) TO Test1
BIND FPtr(2) TO Test2
FOR K = 1 TO 2
  CALLFUNC(FPtr(K), 10 + K)
NEXT
CALLFUNC FPtr(2), 7
BIND FnPtr2 TO Twice
PRINT "twice "; CALLFUNC(FnPtr2, 21)
DIM LRes AS LONG
LRes = (CALLFUNC(FnPtr2, 5))
PRINT "lres "; LRes
' template without a body (chapter 11.4)
BIND Template TO MyFuncTemp
Template = FnPtr2
PRINT "template "; CALLFUNC(Template, 100)

' CODEPTR: subclassing with SetWindowLong
OldEditProc = SetWindowLongAPI(Edit1.Handle, GWL_WNDPROC, CODEPTR(EditWndProc))
FOR K = 1 TO 500
  SendMessage Edit1.Handle, WM_USER + 3, 1, 0
NEXT
PRINT "codeptr "; EditCount; " "; (OldEditProc <> 0)

' as in RQdebugger: NewWndProc.Inc
BIND iTmpBind TO ListWndProc
OldListProc = SetNewWndProc(List1.Handle, iTmpBind)
FOR K = 1 TO 300
  SendMessage List1.Handle, WM_USER + 4, 0, 0
NEXT
PRINT "setnewwndproc "; ListCount; " "; (OldListProc <> 0)
List1.AddItems "a", "b"
PRINT "list still works "; List1.ItemCount

' CODEPTR for EnumChildWindows (2 parameters)
EnumChildWindows Form.Handle, CODEPTR(EnumProc), 1
PRINT "children "; ChildCount
' CallBack_4.Inc: SetNewCallBack_4 for SetTimer
BIND hTimer TO TimerProc
SetTimer Form.Handle, 77, 20, SetNewCallBack_4(hTimer)
FOR K = 1 TO 100
  DOEVENTS
  SLEEP 0.01
  IF TimerCount >= 2 THEN EXIT FOR
NEXT
KillTimer Form.Handle, 77
PRINT "timer "; (TimerCount >= 2)
