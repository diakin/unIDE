$APPTYPE CONSOLE
' PRIVATE / PUBLIC before TYPE, CONST, DECLARE, SUB (inc/Form.inc: Private Type POINTAPI)
Private Type PT
  x As Long
  y As Long
End Type
Public Const K = 5
Private Declare Function GetTickCount Lib "kernel32" Alias "GetTickCount" () As Long
Private Sub Show2 (A As INTEGER)
  PRINT "sub "; A
End Sub
DIM P AS PT
P.x = 3 : P.y = 4
Show2 K
PRINT P.x + P.y; " "; (GetTickCount() <> 0)
