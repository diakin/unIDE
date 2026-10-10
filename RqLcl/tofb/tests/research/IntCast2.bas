' INT при rapidq.inc: там $define int integer, а INTEGER(x) возвращает x
' без изменений (IntCast.bas). Что печатает INT(2.7) с rapidq.inc?
$APPTYPE CONSOLE
$INCLUDE "RAPIDQ.INC"
PRINT "INT(2.7) -> "; INT(2.7)
PRINT "INT(-2.7) -> "; INT(-2.7)
INPUT "Enter", Answer$
