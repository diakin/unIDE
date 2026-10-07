$APPTYPE CONSOLE
' CASE = x as CASE x (RapidQ test 2026-10-08: x = 0 -> eq0); strings too
' (rapidq2.inc: CASE = "MOUS")
DIM S AS STRING
x = 0
SELECT CASE x
CASE = 0 : PRINT "eq0"
CASE ELSE : PRINT "else"
END SELECT
x = 1
SELECT CASE x
CASE = 0
  PRINT "eq0"
CASE = 1
  PRINT "eq1"
END SELECT
S = "KEYB"
SELECT CASE S
CASE = "MOUS" : PRINT "mouse"
CASE = "KEYB" : PRINT "keyboard"
END SELECT
