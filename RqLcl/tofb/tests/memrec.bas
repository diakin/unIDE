$APPTYPE CONSOLE
' MEMCPY, MEMSET, MEMCMP with a record variable instead of an address (as in
' rapidq2.inc: MEMCPY(gRQ2_MeasureItem, lParam, ...), MEMSET(DevM, 0, ...)):
' global, array element, local in SUB, field of own component (This.P)
TYPE TPoint
  X AS LONG
  Y AS LONG
END TYPE
TYPE QHolder EXTENDS QOBJECT
  P AS TPoint
  SUB Clear
    MEMSET(This.P, 0, SIZEOF(TPoint))
  END SUB
END TYPE
DIM Pt AS TPoint, Pt2 AS TPoint
DIM Pts(2) AS TPoint
Pt.X = 3 : Pt.Y = 4
MEMCPY(Pt2, VARPTR(Pt), SIZEOF(TPoint))
PRINT "copy "; Pt2.X; " "; Pt2.Y
MEMCPY Pts(1), Pt, SIZEOF(TPoint)
PRINT "elem "; Pts(1).X; " "; Pts(1).Y
PRINT "cmp "; MEMCMP(Pt, Pts(1), SIZEOF(TPoint))
SUB LocalRec
  DIM Lr AS TPoint
  Lr.X = 9
  MEMSET(Lr, 0, SIZEOF(Lr))
  PRINT "local "; Lr.X
END SUB
LocalRec
DIM H AS QHolder
H.P.X = 5
H.Clear
PRINT "field "; H.P.X
