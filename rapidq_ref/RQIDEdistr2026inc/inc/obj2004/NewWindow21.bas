'$INCLUDE "RAPIDQ.INC"
'--- Declarations ---
$INCLUDE "RapidQ2.inc"  'just for the QDebug component
DECLARE Function KeyboardProc_
(ByVal idHook As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
DECLARE SUB OnFormClose()
DECLARE SUB OnFormShow()

' * SetWindowsHook() codes
'
$DEFINE WH_MIN              (-1)
$DEFINE WH_MSGFILTER        (-1)
$DEFINE WH_JOURNALRECORD    0
$DEFINE WH_JOURNALPLAYBACK  1
$DEFINE WH_KEYBOARD         2
$DEFINE WH_GETMESSAGE       3
$DEFINE WH_CALLWNDPROC      4
$DEFINE WH_CBT              5
$DEFINE WH_SYSMSGFILTER     6
$DEFINE WH_MOUSE            7
$DEFINE WH_HARDWARE         8
$DEFINE WH_DEBUG            9
$DEFINE WH_SHELL           10
$DEFINE WH_FOREGROUNDIDLE  11
'#if(WINVER >= 0x0400)
$DEFINE WH_CALLWNDPROCRET  12
'#endif / WINVER >= 0x0400 /

'#if (_WIN32_WINNT >= 0x0400)
$DEFINE WH_KEYBOARD_LL     13
$DEFINE WH_MOUSE_LL        14
'#endif // (_WIN32_WINNT >= 0x0400)

'#if(WINVER >= 0x0400)
'#if (_WIN32_WINNT >= 0x0400)
$DEFINE WH_MAX             14
'#else
'$DEFINE WH_MAX             12
'#endif // (_WIN32_WINNT >= 0x0400)
'#else
'$DEFINE WH_MAX             11
'#endif

'$DEFINE WH_MINHOOK         WH_MIN
'$DEFINE WH_MAXHOOK         WH_MAX

'Public Const WH_KEYBOARD = 2
'Public Const VK_SHIFT = &H10

Declare Function CallNextHookEx Lib "user32" ALIAS "CallNextHookEx" _
(hHook As Long, ncode As Long, wParam As Long, lParam As LONG) As Long
'Declare Function GetKeyState Lib "user32" ALIAS "GetKeyState" (ByVal nVirtKey As Long) As Integer

Declare Function SetWindowsHookEx Lib "user32" Alias "SetWindowsHookExA" (idHook As Long, lpfn As Long,  hmod As Long, dwThreadId As dword) As Long
Declare Function UnhookWindowsHookEx Lib "user32" ALIAS "UnhookWindowsHookEx" (hHook As Long) As Long
Declare Function GetCurrentThreadId Lib "kernel32" Alias "GetCurrentThreadId"() As Long

DIM hHook As Long

DIM D as Qdebug 
CREATE Form1 AS QFORM
	OnClose = OnFormClose
	left = 120
	CREATE myEdit AS QEDIT
		Text = "here is some text"
	END CREATE
END CREATE

'set a keyboard hook
DEFLNG lpHookProc = CODEPTR(KeyboardProc)
DEFLNG ThreadID = GetCurrentThreadId()

hHook = SetWindowsHookEx(WH_KEYBOARD,CODEPTR(KeyboardProc),0&, ThreadID) 'WH_MOUSE 'WH_KEYBOARD
Form1.ShowModal

Function KeyboardProc(idHook As Long, wParam As Long, lParam As Long) As Long
'if idHook is less than zero, no further processing is required
If idHook < 0 Then
	'call the next hook
	KeyboardProc = CallNextHookEx(hHook, idHook, wParam, lParam)
Else
	'check if SHIFT-S is pressed
	If (GetKeyState(VK_SHIFT) And &HF0000000) And wParam = Asc("S") Then
	'show the result
	Form1.TextOut(10,10, "Shift-S pressed ...", &H0,&HFFFFFF)
End If
'call the next hook
KeyboardProc = CallNextHookEx(hHook, idHook, wParam, lParam)
D.Print str$(wParam)  'chr$(wParam)
End If
End Function

SUB OnFormClose()
'remove the windows-hook
UnhookWindowsHookEx hHook
End Sub
