$IFNDEF __QPOINT_INC   ' IncManager: include guard
$DEFINE __QPOINT_INC
Type QPoint
    X as long
    Y as long
End Type

Sub Point(FPoint as QPoint, x as long, y as long)
FPoint.X = x
FPoint.Y = y
End Sub

$ENDIF   ' IncManager: __QPOINT_INC
