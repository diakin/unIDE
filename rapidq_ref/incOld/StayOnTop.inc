'$Include "Win32API.inc"
$OPTION VBDLL ON
$OPTION WEAKTYPE ON

declare function SetWindowPos Lib "User32" alias "SetWindowPos" (ByVal hwnd as long,ByVal hwndInsertAfter as Long, _
ByVal x as long, ByVal y as Long,ByVal cx as Long,ByVal cy as Long, _
ByVal wFlags as Long)as Long

declare sub StayOnTop(hwnd as QForm)

Const SWP_NOMOVE=&H2
Const SWP_NOSIZE=&H1
Const HWND_TOPMOST= -1
Const FLAGS = SWP_NOMOVE Or SWP_NOSIZE
dim OnTop as integer

Create StayOnTopTimer as QTimer
Interval=1
Enabled=1
OnTimer=StayOnTop
End Create

SUB StayOnTop(hwnd as QForm)
OnTop=SetWindowPos(hwnd.Handle,HWND_TOPMOST,0,0,0,0,FLAGS)
End SUB
 
' Form.ShowModal
$TYPECHECK OFF
$OPTION VBDLL OFF
$OPTION WEAKTYPE OFF
