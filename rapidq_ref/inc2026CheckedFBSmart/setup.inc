Declare Function SetWindowLong Lib "user32" Alias "SetWindowLongA" (hwnd As Long, nIndex As Long, dwNewLong As Long) As Long 

Sub MinSet (fhand as integer, apphand as integer)
    setwindowlong(fhand, -8, 0)
    setwindowlong(apphand, -8, fhand)
End Sub  