$APPTYPE CONSOLE
' Test 2: is an object DIMmed inside a FUNCTION created anew on every call,
' or does it keep its contents from the previous call (like STATIC)?
' Probe is called three times with texts of different length.
' "enter:" is printed before anything is written on this call.

FUNCTION Probe(InpStr AS STRING) AS LONG
DIM Mem AS QMemoryStream
DIM Lst AS QStringList
DIM N AS LONG
PRINT "  enter: Mem.Size="; Mem.Size; " Mem.Position="; Mem.Position; " Lst.ItemCount="; Lst.ItemCount; " N="; N
Mem.Write InpStr
Lst.AddItems InpStr
N = N + 1
Mem.Position = 0
Probe = Mem.Pointer
END FUNCTION

' text at an address: exactly N bytes, codes of non-printable bytes in []
FUNCTION PeekText(Addr AS LONG, N AS LONG) AS STRING
DIM Buf AS STRING
DIM Res AS STRING
DIM K AS LONG
Buf = SPACE$(N)
MEMCPY(VARPTR(Buf), Addr, N)
Res = ""
FOR K = 1 TO N
  IF ASC(MID$(Buf, K, 1)) < 32 OR ASC(MID$(Buf, K, 1)) > 126 THEN
    Res = Res + "[" + STR$(ASC(MID$(Buf, K, 1))) + "]"
  ELSE
    Res = Res + MID$(Buf, K, 1)
  END IF
NEXT K
PeekText = Res
END FUNCTION

DIM A1 AS LONG, A2 AS LONG, A3 AS LONG
PRINT "call 1 AAAA"
A1 = Probe("AAAA")
PRINT "  address "; A1; " text "; PeekText(A1, 8)
PRINT "call 2 BBBBBBBB"
A2 = Probe("BBBBBBBB")
PRINT "  address "; A2; " text "; PeekText(A2, 8)
PRINT "call 3 CC"
A3 = Probe("CC")
PRINT "  address "; A3; " text "; PeekText(A3, 8)
PRINT "  text at 1st address "; PeekText(A1, 8)
PRINT "end"
