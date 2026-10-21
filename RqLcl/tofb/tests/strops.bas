$APPTYPE CONSOLE
' s$[N], string subtraction, x++ (operators.html, loops.html; s$[N] and
' the error on s[5] = "x" - RapidQ test 2026-10-08)
DIM T AS STRING
DIM Count AS INTEGER, Num AS INTEGER, Path$ AS STRING
S$="123456"
print"9:s$[0]=";s$[0]
print"11:s$[1]=";s$[1]
print"11:s$[8]=";s$[8]
T = "abc9x"
FOR Num = 1 TO LEN(T)
  IF T[Num] >= "0" AND T[Num] <= "9" THEN PRINT "digit at "; Num
NEXT Num
PRINT "asc "; ASC(T[2]); " last "; T[LEN(T)]
PRINT "jello" - "l"
Path$ = "[Folder]"
PRINT Path$ - "[" - "]"; " "; "a-b-c" - "-" + "!"; " "; "x" + "aab" - "a"
PRINT "num "; 10 - 3 - 2; " "; LEN("abc" - "b") - 1
FUNCTION CountChar (sSearchIn AS STRING, sToFind AS STRING) AS LONG
  DEFINT iCharCounter = 0
  FOR N = 1 TO LEN(sSearchIn)
    IF sSearchIn[N] = sToFind THEN iCharCounter ++
  NEXT N
  Result = iCharCounter
END FUNCTION
PRINT "tally "; CountChar("banana", "a")
Count = 5
Count ++
Count++
PRINT "count "; Count
