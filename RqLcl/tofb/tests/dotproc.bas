$APPTYPE CONSOLE
' SUB / FUNCTION with a dot in the name (rapidq2.inc: FUNCTION Screen.MousePresent,
' Screen.EnumResolution(ListView AS QLISTBOX), Screen.CaptureToBMP = retrn)
DIM Total AS LONG

FUNCTION Screen.Twice(Value AS LONG) AS LONG
  DIM Local1 AS LONG
  Local1 = Value * 2
  Screen.Twice = Local1
END FUNCTION

FUNCTION Screen.Plus(Value AS LONG) AS LONG
  DIM Local1 AS LONG
  Local1 = Value + 1
  Result = Local1
END FUNCTION

SUB Application.AddTotal(Value AS LONG)
  Total = Total + Value
END SUB

FUNCTION Application.Name2 AS STRING
  Result = "app"
END FUNCTION

PRINT "twice "; Screen.Twice(21)
PRINT "plus "; Screen.Plus(Screen.Twice(5))
Application.AddTotal 3
Application.AddTotal(4)
CALL Application.AddTotal(5)
PRINT "total "; Total
PRINT "name "; Application.Name2
PRINT "width ok "; (Screen.Width > 0)
