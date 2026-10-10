'QRPANEL is a sister component to QRFORM. It gives you the ability to create a panel with rounded corners.
'Thanks to everybody at the Yahoo board who shared their knowledge to build this one up :)
'
'Created the 1st of April 2004
'=========================================================================================================
'USEAGE:
'You need to pay attention to the special added event in QRPANEL. The "rBorder" - when you create panels
'with the QRPANEL component they will actually first get round corners when you set this to 1
'( rBorder = 1 ).
'Also RndX and RndY is new things - these 2 controls just how "round" the corners of the QRPANEL is.
'If you set these 2 high enough, you'll actually be able to make completely round panels.

Declare Function CreateRoundRectRgn Lib "gdi32"Alias "CreateRoundRectRgn" (X1 As Long, Y1 As Long, X2 As Long, Y2 As Long, X3 As Long, Y3 As Long) As Long
Declare Function SetWindowRgn Lib "user32" Alias "SetWindowRgn" (hwnd As Long, hRgn As Long, bRedraw As Long) As Long
Declare Function DeleteObject Lib "gdi32" Alias "DeleteObject" (hObject As Long) As Long

TYPE QrPanel EXTENDS QPanel
RndX AS Long
RndY AS Long
rBorder as byte PROPERTY SET Paint

PROPERTY SET paint(flag as byte)
DIM QpRegion AS Long

WITH this
.rBorder = flag
if flag>0 then
QpRegion = CreateRoundRectRgn(0,0,.Width,.Height,.RndX,.RndY)
SetWindowRgn .handle, QpRegion, True
end if
END WITH
END PROPERTY

CONSTRUCTOR
RndX=20
RndY=20
Width = 100
Height = 100
rBorder = 0
END CONSTRUCTOR
END TYPE
