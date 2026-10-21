$APPTYPE CONSOLE
' CASE a TO b, c TO d and CASE IS > x (conditions.html)
FOR x = 0 TO 300 STEP 50
SELECT CASE x
  CASE 1 TO 4, 10 TO 20
    PRINT x; " a"
  CASE 100 TO 150
    PRINT x; " b"
  CASE IS > 200
    PRINT x; " c"
  CASE ELSE
    PRINT x; " else"
END SELECT
NEXT x
