Const HWND_TOPMOST = -1
Const HWND_NOTOPMOST = -2
Const SWP_NOSIZE = &H1
Const SWP_NOMOVE = &H2
Const SWP_NOACTIVATE = &H10
Const SWP_SHOWWINDOW = &H40

Declare Function BringWindowToTop Lib "user32" Alias "BringWindowToTop"_
(ByVal hwnd As Long) As Long

Declare Function FindWindow Lib "user32" Alias "FindWindowA" _
(className As String, windowName As String) As Integer
                 
Declare Sub SetWindowPos Lib "user32" ALIAS "SetWindowPos"(hWnd As Long,_
hWndInsertAfter As Long, X As Long, Y As Long, cx As Long, cy As Long,_
wFlags As Long)

Declare Function ShellExecute Lib "shell32.dll" Alias "ShellExecuteA" _
(ByVal hwnd As Long, ByVal lpOperation As String, ByVal lpFile As string, _
ByVal lpParameters As String, ByVal lpDirectory As String, _
ByVal nShowCmd As Long) As Long

Declare Function SetForegroundWindow Lib "user32" Alias _
"SetForegroundWindow" (hwnd As Long) As Long

Declare Function SetParent Lib "user32" Alias _
"SetParent"(hWndChild as Long, hWndNewParent as Long) as long

Declare Function LoadLibrary Lib "kernel32" Alias "LoadLibraryA" _
(LibFileName As String) As Long

Declare Function FreeLibrary Lib "kernel32" Alias "FreeLibrary" _
(hInst As Long) As Long

Declare Function LoadCursor Lib "user32" Alias "LoadCursorA" _
(hInst As Long, CursorName As String) As Long

Declare Function LoadCursorFromFile Lib "user32" Alias "LoadCursorFromFileA" _
(CursorFileName As String) As Long

Declare Function SetWindowLong LIB "User32" Alias "SetWindowLongA"_
(hwnd AS Long, nIndex AS Long, dwNewLong AS Long) As Long

Declare Function GetWindowLong Lib "user32" Alias "GetWindowLongA"_
(hwnd As Long, nIndex As Long) As Long

Declare Function GetKeyState Lib "user32" Alias "GetKeyState"_
(nVirtKey As Long) As Integer


