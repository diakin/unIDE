$APPTYPE CONSOLE
' CODEPTR(Type.Method) inside a TYPE: each object gets its own callback
' thunk (QColorDialog.inc: CODEPTR(QCOLORDIALOG.HookProc))
DECLARE FUNCTION CallProc LIB "user32" ALIAS "CallWindowProcA" (lpPrevWndFunc AS LONG, hWnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG

TYPE QCOUNTER EXTENDS QOBJECT
  Count AS LONG
  Tag AS STRING
  Addr AS LONG

  FUNCTION HookProc(hWnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
    QCOUNTER.Count = QCOUNTER.Count + 1
    Result = hWnd + uMsg * 10 + wParam * 100 + lParam * 1000
  END FUNCTION

  SUB TakeAddr
    QCOUNTER.Addr = CODEPTR(QCOUNTER.HookProc)
  END SUB
END TYPE

DIM CounterA AS QCOUNTER
DIM CounterB AS QCOUNTER
CounterA.Tag = "A"
CounterB.Tag = "B"
CounterA.TakeAddr
CounterB.TakeAddr
CounterA.TakeAddr
PRINT "same addr again "; (CounterA.Addr <> CounterB.Addr)
PRINT "A call "; CallProc(CounterA.Addr, 1, 2, 3, 4)
PRINT "B call "; CallProc(CounterB.Addr, 5, 6, 7, 8)
PRINT "A call "; CallProc(CounterA.Addr, 1, 0, 0, 0)
PRINT CounterA.Tag; " count "; CounterA.Count
PRINT CounterB.Tag; " count "; CounterB.Count
