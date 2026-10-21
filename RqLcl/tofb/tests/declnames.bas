$APPTYPE CONSOLE
' Parameter names in DECLARE and in the SUB/FUNCTION header differ: RapidQ
' uses the DECLARE names (user test 2026-10-08: PRINT A, B -> 50)
DECLARE SUB T (A AS LONG)
SUB T (B AS LONG)
  PRINT A, B
END SUB
T 5
' as in CallBack_2.Inc: Declare ... (hFunction ...), Function ... (cbIndex ...)
DECLARE FUNCTION Master (hFunction AS LONG, Arg1 AS LONG) AS LONG
FUNCTION Master (cbIndex AS LONG, Arg1 AS LONG) AS LONG
  Master = hFunction * 100 + Arg1 + cbIndex
END FUNCTION
PRINT Master(7, 3)
' same names, other case: nothing changes
DECLARE SUB U (Value AS LONG)
SUB U (VALUE AS LONG)
  PRINT Value
END SUB
U 9
