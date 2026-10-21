$APPTYPE CONSOLE
' Test: what SADD (from conversion.inc) returns and whether the address is
' still valid after the function returns.
' SADD puts the string into a local QMemoryStream and returns Mem.Pointer.
' Questions:
'  1. Is it the address of the caller's string (as the comment says) or of
'     a copy inside the stream?
'  2. After SADD returns, does the address still hold the text, or is the
'     memory freed and reused?

FUNCTION sadd(InpStr AS STRING) AS LONG
'Returns the memory offset of the string data in the string variable
' use as pointer to the string variable
DIM Mem AS QMemoryStream
Mem.Write InpStr
Mem.Position = 0
sadd=Mem.Pointer
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

DIM S1 AS STRING
DIM A1 AS LONG, A2 AS LONG, A3 AS LONG
DIM Filler(20) AS STRING
DIM K2 AS LONG

S1 = "FIRST-STRING-1234"

' 1. address of the variable vs. address from SADD
A1 = sadd(S1)
PRINT "1. VARPTR(S1)   = "; VARPTR(S1)
PRINT "   sadd(S1)     = "; A1
IF A1 = VARPTR(S1) THEN PRINT "   same address" ELSE PRINT "   different address (copy)"

' 2. text at the SADD address right after the call
PRINT "2. text at sadd = "; PeekText(A1, LEN(S1))

' 3. second call with other text: is the same memory used again?
A2 = sadd("SECOND-TEXT-ABCDE")
PRINT "3. second sadd  = "; A2
IF A2 = A1 THEN PRINT "   same address as first call" ELSE PRINT "   other address"
PRINT "   text at 1st  = "; PeekText(A1, LEN(S1))
PRINT "   text at 2nd  = "; PeekText(A2, LEN(S1))

' 4. other allocations, then read the first address again
FOR K2 = 0 TO 20
  Filler(K2) = STRING$(17, CHR$(65 + (K2 MOD 26)))
NEXT K2
DIM Other AS QMemoryStream
Other.Write "OTHER-STREAM-XYZ!"
A3 = Other.Pointer
PRINT "4. global stream = "; A3
PRINT "   text at 1st  = "; PeekText(A1, LEN(S1))
PRINT "   text at 2nd  = "; PeekText(A2, LEN(S1))
PRINT "   text at glob = "; PeekText(A3, 17)

' 5. global stream, 20 bytes: what follows the 17 bytes of data
PRINT "5. 20 bytes     = "; PeekText(A3, 20)
PRINT "end"
