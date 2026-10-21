Declare Function OpenProcessToken Lib "advapi32" Alias "OpenProcessToken" (ProcessHandle As Long, DesiredAccess As Long, TokenHandle As Long) As Long
Declare Function GetCurrentProcess Lib "kernel32" Alias "GetCurrentProcess" () As Long
Declare Function CloseHandle Lib "kernel32" Alias "CloseHandle" (hObject As Long) As Long
DIM Thndl AS LONG, ret AS LONG
ret = OpenProcessToken(GetCurrentProcess(), &H8, @Thndl)
PRINT "ret=" + STR$(ret) + " handle=" + STR$(Thndl)
CloseHandle Thndl
