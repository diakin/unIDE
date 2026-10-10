' INTEGER(x) как функция (rapidq2.inc: integer((a - b) / 2),
' integer(powr.BatteryFlag)). Что даёт: отбрасывание дробной части,
' округление или ошибку компиляции.
$APPTYPE CONSOLE
DIM Dbl AS DOUBLE
Dbl = 2.7 : PRINT "2.7 -> "; INTEGER(Dbl)
Dbl = -2.7 : PRINT "-2.7 -> "; INTEGER(Dbl)
Dbl = 2.5 : PRINT "2.5 -> "; INTEGER(Dbl)
Dbl = 3.5 : PRINT "3.5 -> "; INTEGER(Dbl)
PRINT "INT(2.7) -> "; INT(2.7); "  INT(-2.7) -> "; INT(-2.7)
INPUT "Enter", Answer$
