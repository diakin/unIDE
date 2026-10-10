' FOR со счётчиком-полем (FreeBASIC так не умеет - WHILE ... WEND), EXIT FOR
' в нём, x--, SWAP (a, b), DEFINT вне процедур со значением-выражением,
' параметр с именем функции FreeBASIC (hex), ABS(запись) - адрес записи
$APPTYPE CONSOLE
TYPE TRec
  A AS LONG
  B AS LONG
END TYPE
TYPE TCnt EXTENDS QOBJECT
  Idx AS INTEGER
  Total AS INTEGER
  SUB Run
    FOR This.Idx = 1 TO 5
      This.Total = This.Total + This.Idx
      IF This.Idx = 4 THEN EXIT FOR
    NEXT This.Idx
    PRINT This.Total
    PRINT This.Idx
    FOR This.Idx = 6 TO 2 STEP -2
      PRINT This.Idx
    NEXT
  END SUB
END TYPE
DIM Cnt AS TCnt
Cnt.Run
DEFINT Base1 = 10
DEFINT Calc1 = Base1 * 2 + 1
PRINT Calc1
DIM Num AS INTEGER
Num = 3
Num--
PRINT Num
DIM S1 AS STRING, S2 AS STRING
S1 = "a" : S2 = "b"
SWAP (S1, S2)
PRINT S1 + S2
FUNCTION HexLen(hex AS STRING) AS LONG
  RESULT = LEN(hex)
END FUNCTION
PRINT HexLen("1F")
DIM Rec AS TRec
IF ABS(Rec) <> 0 THEN PRINT "addr"
' LIBRARYINST, UNLOADLIBRARY (ничего не делает), SOUND, повторный DECLARE
IF LIBRARYINST("kernel32") <> 0 THEN PRINT "lib"
UNLOADLIBRARY("kernel32")
SOUND 440, 0
DECLARE SUB Twice
DECLARE SUB Twice
SUB Twice
  PRINT "twice"
END SUB
Twice
