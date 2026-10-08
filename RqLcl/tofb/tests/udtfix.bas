$APPTYPE CONSOLE
' STRING*N in TYPE (user test in RapidQ 2026-10-08): SIZEOF 9, "ab" padded
' with spaces (bytes 97 98 32 32 32), "1234567" cut to "12345"; fields
' without alignment; array of fixed strings in TYPE
TYPE T
  S AS STRING*5
  N AS INTEGER
END TYPE
TYPE TNames
  Count AS BYTE
  Names(1 TO 3) AS STRING*4
  Tail(2) AS STRING*2
END TYPE
DIM TT AS T, T2 AS T
DIM M AS QMEMORYSTREAM
DIM I AS INTEGER
TT.S = "ab"
PRINT "["; TT.S; "]"; LEN(TT.S); SIZEOF(TT)
M.WriteUDT(TT)
M.Position = 0
FOR I = 1 TO 5
  PRINT M.ReadNum(1);
NEXT
PRINT
TT.S = "1234567"
PRINT "["; TT.S; "]"; LEN(TT.S)
TT.N = 42
M.Position = 0
M.WriteUDT(TT)
M.Position = 0
M.ReadUDT(T2)
PRINT "["; T2.S; "]"; T2.N; M.Size
WITH TT
  .S = "w"
END WITH
PRINT "["; TT.S; "]"
DIM NM AS TNames
NM.Names(1) = "one"
NM.Names(3) = "three"
NM.Tail(2) = "xyz"
PRINT SIZEOF(NM); " ["; NM.Names(1); "]["; NM.Names(3); "]["; NM.Tail(2); "]"
