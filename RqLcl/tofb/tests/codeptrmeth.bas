$APPTYPE CONSOLE
' CODEPTR(Type.Method) inside a TYPE: callback thunk calls the method of the object
' whose method took the address (QColorDialog.inc: CODEPTR(QCOLORDIALOG.HookProc))
DECLARE FUNCTION CallProc LIB "user32" ALIAS "CallWindowProcA" (lpPrevWndFunc AS LONG, hWnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG

TYPE QCOUNTER EXTENDS QOBJECT
  Count AS LONG
  Tag AS STRING

  FUNCTION HookProc(hWnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
    QCOUNTER.Count = QCOUNTER.Count + 1
    Result = hWnd + uMsg * 10 + wParam * 100 + lParam * 1000
  END FUNCTION

  FUNCTION Run AS LONG
    Result = CallProc(CODEPTR(QCOUNTER.HookProc), 1, 2, 3, 4)
  END FUNCTION
END TYPE

DIM CounterA AS QCOUNTER
DIM CounterB AS QCOUNTER
CounterA.Tag = "A"
CounterB.Tag = "B"
PRINT "A.Run="; CounterA.Run
PRINT "B.Run="; CounterB.Run
PRINT "B.Run="; CounterB.Run
PRINT CounterA.Tag; " count "; CounterA.Count
PRINT CounterB.Tag; " count "; CounterB.Count
