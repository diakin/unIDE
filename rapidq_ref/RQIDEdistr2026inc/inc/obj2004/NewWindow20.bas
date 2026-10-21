$INCLUDE "RAPIDQ.INC"

'--- Declarations ---
'In a module

Declare Function CreateThread Lib "kernel32" Alias "CreateThread" (lpThreadAttributes As long, dwStackSize As Long,_
lpStartAddress As Long, lpParameter As long, dwCreationFlags As Long, byref lpThreadId As Long) As Long


Declare Function TerminateThread Lib "kernel32" Alias "TerminateThread" ( hThread As Long,  dwExitCode As Long) As Long

Declare Function GetThreadPriority Lib "kernel32" Alias "GetThreadPriority" (hThread As Long) As Long

Declare Function SetThreadPriority Lib "kernel32" Alias "SetThreadPriority" (hThread As Long,nPriority As Long) As Long
Declare Function CloseHandle Lib "kernel32"  Alias "CloseHandle" (hObject As Long) As Long

Declare Sub Command1_Click()
Declare Sub Form_Unload(Cancel As Integer)
Declare Sub AsyncThread()


dim hThread As Long, hThreadID As Long



'Using the CreateThread function in Visual Basic
'is very risky! VB5 is 'kinda' stable, but VB6
'applications will probably crash when you
'use the CreateThread function.

'In a form
'Add a command button to the form




CREATE Form AS QFORM
	Caption = "Form1"
	Width = 640
	Height = 480
	Center
	
	CREATE Button1 AS QBUTTON
		Caption = "Thread"
		Left = 4
		Top = 4
		TabOrder = 8
		OnClick=Command1_Click
	END CREATE
	
	CREATE Button2 AS QBUTTON
		Caption = "No thread"
		Left = 140
		Top = 4
		TabOrder = 8
		OnClick=AsyncThread
	END CREATE
	
	
END CREATE

dim IdThread as long
IdThread=0
dim PtVar as long
dim PtSub as long

PtVar=varptr(IdThread)
print"PtVar=";PtVar
PtSub=CODEPTR(AsyncThread)
print"PtSub=";PtSub

'this.hThread=CreateThread(0,0,PtSub,0,0,PtVar)

Form.ShowModal  






'*****************************
Sub Command1_Click
'KPD-Team 1999
'URL: http://www.allapi.net/
'E-Mail: KPDTeam@Allapi.net
'After you click this button, try to move the window
'You will see that the AsyncThread-function was executed asynchronously

IdThread = CreateThread(0&, 0&, PtSub,  0&, 0&, PtVar)
print"PtVar=";PtVar
print"hThread=";hThread
CloseHandle IdThread
End Sub

'*****************************
Sub Form_Unload
'If the thread is still running, close it
If hThread <> 0 Then TerminateThread hThread, 0
End Sub



'*****************************
Sub AsyncThread
'Let this thread sleep for 10 seconds
for i=0 to 10
Button2.caption=str$(i)
'doevents
Sleep 0.300
next i

hThread = 0
End Sub
