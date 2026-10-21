'USER32.DLL Functions
'FILE ADDED: Release Version 1
'FILE UPDATED: Release Version 3

'Adapted for RapidQ by Bryn Mosher (bdmnky@hotmail.com)
'WIN32API RapidQ $Includes
'Home page - http://home.pacbell.net/brynm/
'RapidQ - http://www.basicguru.com/abc/rapidq/

'Thanks to:
'William Yu for RegisterHotKey, UnRegisterHotKey, and SetForegroundWindow.
'Not to mention the compiler ;)


'FindWindow()

	Declare Function FindWindow Lib "user32.dll" Alias_
	 "FindWindowA" (lpClassName As String, lpWindowName As String) As Long 


'GetActiveWindow

	Declare Function GetActiveWindow Lib "user32.dll" Alias_
	 "GetActiveWindow" As Long


'GetCapture()

	Declare Function GetCapture Lib "user32.dll" Alias_
	 "GetCapture" As Long


'GetClassName

	Declare Function GetClassName Lib "user32.dll" Alias_
	 "GetClassNameA" (hWnd As Long, lpClassName As String,_
	 nMaxCount As Long) As Long


'GetCursor()

	Declare Function GetCursor Lib "user32.dll" Alias_
	 "GetCursor" As Long


'GetDeskTopWindow()

	Declare Function GetDesktopWindow Lib "user32.dll" Alias_
	 "GetDesktopWindow" As Long


'GetDialogBaseUnits()

	Declare Function GetDialogBaseUnits Lib "user32.dll" Alias_
	 "GetDialogBaseUnits" As Long


'GetDoubleClickTime()

	Declare Function GetDoubleClickTime Lib "user32.dll" Alias_
	 "GetDoubleClickTime" As Long


'GetFocus()

	Declare Function GetFocus Lib "user32.dll" Alias_
	 "GetFocus" As Long


'GetForegroundWindow()

	Declare Function GetForegroundWindow Lib "user32.dll" Alias_
	 "GetForegroundWindow" As Long


'GetInputState()

	Declare Function GetInputState Lib "user32.dll" Alias_
	 "GetInputState" As Long


'GetKBCodePage()

	Declare Function GetKBCodePage Lib "user32.dll" Alias_
	 "GetKBCodePage" As Long


'GetMenuCheckMarkDimensions()

	Declare Function GetMenuCheckMarkDimensions Lib "user32.dll" Alias_
	 "GetMenuCheckMarkDimensions" As Long


'GetMessageExtraInfo()

	Declare Function GetMessageExtraInfo Lib "user32.dll" Alias_
	 "GetMessageExtraInfo" As Long


'GetMessagePos()

	Declare Function GetMessagePos Lib "user32.dll" Alias_
	 "GetMessagePos" As Long


'GetMessageTime()

	Declare Function GetMessageTime Lib "user32.dll" Alias_
	 "GetMessageTime" As Long


'GetOpenClipboardWindow()

	Declare Function GetOpenClipboardWindow Lib "user32.dll" Alias_
	 "GetOpenClipboardWindow" As Long


'GetProcessWindowStation()

	Declare Function GetProcessWindowStation Lib "user32.dll" Alias_
	 "GetProcessWindowStation" As Long


'GetSystemMetrics()
	'Gets system info.  Index at msdn.microsoft.com
	'EXAMPLE:
		'Select Case GetSystemMetrics(SM_CLEANBOOT)
		'	Case 0
		'		ShowMessage "Normal system boot."
		'	Case 1
		'		ShowMessage "You are in safe mode."
		'	case 2
		'		ShowMessage "You are in safe mode with networking."
		'end select

	' GetSystemMetrics constants
		Const SM_CXSCREEN = 0
		Const SM_CYSCREEN = 1
		Const SM_CXVSCROLL = 2
		Const SM_CYHSCROLL = 3
		Const SM_CYCAPTION = 4
		Const SM_CXBORDER = 5
		Const SM_CYBORDER = 6
		Const SM_CXDLGFRAME = 7
		Const SM_CYDLGFRAME = 8
		Const SM_CYVTHUMB = 9
		Const SM_CXHTHUMB = 10
		Const SM_CXICON = 11
		Const SM_CYICON = 12
		Const SM_CXCURSOR = 13
		Const SM_CYCURSOR = 14
		Const SM_CYMENU = 15
		Const SM_CXFULLSCREEN = 16
		Const SM_CYFULLSCREEN = 17
		Const SM_CYKANJIWINDOW = 18
		Const SM_MOUSEPRESENT = 19
		Const SM_CYVSCROLL = 20
		Const SM_CXHSCROLL = 21
		Const SM_DEBUG = 22
		Const SM_SWAPBUTTON = 23
		Const SM_RESERVED1 = 24
		Const SM_RESERVED2 = 25
		Const SM_RESERVED3 = 26
		Const SM_RESERVED4 = 27
		Const SM_CXMIN = 28
		Const SM_CYMIN = 29
		Const SM_CXSIZE = 30
		Const SM_CYSIZE = 31
		Const SM_CXFRAME = 32
		Const SM_CYFRAME = 33
		Const SM_CXMINTRACK = 34
		Const SM_CYMINTRACK = 35
		Const SM_CXDOUBLECLK = 36
		Const SM_CYDOUBLECLK = 37
		Const SM_CXICONSPACING = 38
		Const SM_CYICONSPACING = 39
		Const SM_MENUDROPALIGNMENT = 40
		Const SM_PENWINDOWS = 41
		Const SM_DBCSENABLED = 42
		Const SM_CMOUSEBUTTONS = 43
		Const SM_CMETRICS = 44
	'End GetSystemMetrics constants

	Declare Function GetSystemMetrics Lib "user32.dll" Alias_
	 "GetSystemMetrics" (nIndex As Long) As Long


'GetWindowText()

	Declare Function GetWindowText Lib "user32.dll" Alias_
	 "GetWindowTextA" (hWnd As Long, lpString As String,_
	 nMaxCount As Long) As Long


'GetWindowTextLength()

	Declare Function GetWindowTextLength Lib "user32.dll" Alias_
	 "GetWindowTextLengthA" (hWnd As Long) As Long


'RegisterHotKey()

	DECLARE FUNCTION RegisterHotKey LIB "USER32.dll" ALIAS_
	 "RegisterHotKey" (hWnd AS LONG, ID AS LONG, fsModifiers _
	 AS LONG, vk AS LONG) AS LONG


'SetForegroundWindow()

	Declare Function SetForegroundWindow LIB "USER32.dll" ALIAS_
	 "SetForegroundWindow" (HWnd AS LONG) AS Long


'SetWindowPos()

	Declare Function SetWindowPos Lib "user32.dll" Alias_
	 "SetWindowPos" (hwnd As Long, hWndInsertAfter As Long, x As Long,_
	 y As Long, cx As Long, cy As Long, wFlags As Long) As Long


'SetWindowRgn()
    'Sets the form's Window Rgn
    'Used with other Rgn functions to control the form's
    'display shape.

	Declare Function SetWindowRgn Lib "user32.dll" alias_
	 "SetWindowRgn" (hWnd As Long, hRgn As Long,bRedraw As Long) As Long


'UnRegisterHotKey()

	DECLARE FUNCTION UnRegisterHotKey LIB "USER32.dll" ALIAS_
	 "UnregisterHotKey" (hWnd AS LONG, ID AS LONG) AS LONG


