$APPTYPE CONSOLE
' Objects DIMmed inside a SUB/FUNCTION keep their contents between calls
' (user's test in RapidQ 2026-10-09: QMemoryStream.Size on entry 0, 4, 8,
' QStringList.ItemCount 0, 1, 2, Mem.Pointer the same address); sadd from
' conversion.inc returns an address that stays valid after the call.
' Expected output = what RapidQ printed (addresses replaced by comparisons).

FUNCTION Probe(InpStr AS STRING) AS LONG
DIM Mem AS QMemoryStream
DIM Lst AS QStringList
PRINT "  enter: Mem.Size="; Mem.Size; " Mem.Position="; Mem.Position; " Lst.ItemCount="; Lst.ItemCount
Mem.Write InpStr
Lst.AddItems InpStr
Mem.Position = 0
Probe = Mem.Pointer
END FUNCTION

FUNCTION sadd(InpStr AS STRING) AS LONG
DIM Mem AS QMemoryStream
Mem.Write InpStr
Mem.Position = 0
sadd=Mem.Pointer
END FUNCTION

FUNCTION PeekText(Addr AS LONG, N AS LONG) AS STRING
DIM Buf AS STRING
Buf = SPACE$(N)
MEMCPY(VARPTR(Buf), Addr, N)
PeekText = Buf
END FUNCTION

DIM A1 AS LONG, A2 AS LONG, A3 AS LONG
DIM S1 AS STRING
DIM Filler(20) AS STRING
DIM K AS LONG
PRINT "call 1 AAAA"
A1 = Probe("AAAA")
PRINT "  text "; PeekText(A1, 4)
PRINT "call 2 BBBBBBBB"
A2 = Probe("BBBBBBBB")
PRINT "  same address "; (A2 = A1); " text "; PeekText(A2, 8)
PRINT "call 3 CC"
A3 = Probe("CC")
PRINT "  same address "; (A3 = A1); " text "; PeekText(A3, 8)

S1 = "FIRST-STRING-1234"
A1 = sadd(S1)
PRINT "sadd = VARPTR "; (A1 = VARPTR(S1)); " text "; PeekText(A1, 17)
A2 = sadd("SECOND-TEXT-ABCDE")
PRINT "second sadd same address "; (A2 = A1); " text at 1st "; PeekText(A1, 17)
FOR K = 0 TO 20
  Filler(K) = STRING$(17, CHR$(65 + K))
NEXT K
PRINT "after other strings "; PeekText(A1, 17)
PRINT "end"
