' $DEFINE не заменяет имя члена внутри TYPE (тест пользователя в RapidQ
' 2026-10-10: research/DefCase1.bas, DefCase2.bas); INTEGER(x) - x без
' изменений (research/IntCast.bas: INTEGER(2.5) -> 2.5)
$APPTYPE CONSOLE
$DEFINE TRANSPARENT 1
TYPE TDef EXTENDS QOBJECT
  Transparent AS INTEGER
  CONSTRUCTOR
    Transparent = 5
  END CONSTRUCTOR
END TYPE
DIM DefObj AS TDef
PRINT DefObj.Transparent
DefObj.Transparent = 7
PRINT DefObj.Transparent
PRINT TRANSPARENT
DIM Dbl AS DOUBLE
Dbl = 2.5
PRINT INTEGER(Dbl) * 2
