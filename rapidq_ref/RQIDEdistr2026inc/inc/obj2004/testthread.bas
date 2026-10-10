'$INCLUDE "RAPIDQ.INC"


Type SECURITY_ATTRIBUTES
nLength As Long
lpSecurityDescriptor As Long
bInheritHandle As Long
End Type


sub AddClrString (AddString$, Clr, Sender as QRICHEDIT)
'Add colored string to QRICHEDIT
Sender.SelStart =len (Sender.Text)
Sender.SelLength =Len(AddString$)
Sender.SelAttributes.Color=Clr
Sender.AddStrings AddString$
end sub

'$AppType GUI

'--- Declarations ---
Declare Sub callfuncAsyncThread
Declare Sub AsyncThread1
Declare Sub FormShow
Declare Sub AsyncThreadZZZ


' try create FB dll function and call it in new thread
declare Function  ASYNCTHREADdll lib "fbTreadtFunc.dll" alias "ASYNCTHREAD@4"_
( zzz as long) as long  ', dllpath as string


'*****************
'!!! lpThreadAttributes
'Pointer to a SECURITY_ATTRIBUTES structure that determines whether the returned handle can be inherited by child processes. 
'If lpThreadAttributes is NULL, the handle cannot be inherited.
'!!! dwStackSize
'Specifies the size, in bytes, of the stack for the new thread. If 0 is specified, the stack size defaults to the same size as that of 
'the primary thread of the process. The stack is allocated automatically in the memory space of the process and it is 
'freed when the thread terminates. Note that the stack size grows, if necessary.
'!!!lpStartAddress
'The starting address of the new thread. This is typically the address of a function declared with the WINAPI calling convention that accepts 
'a single 32-bit pointer as an argument and returns a 32-bit exit code. Its prototype is: 'DWORD WINAPI ThreadFunc( LPVOID );
'!!! lpParameter
'Specifies a single 32-bit parameter value passed to the thread
'!!!dwCreationFlags
'Specifies additional flags that control the creation of the thread. If the CREATE_SUSPENDED flag is specified, 
'the thread is created in a suspended state, and will not run until the ResumeThread function is called. 
'If this value is zero, the thread runs immediately after creation. At this time, no other values are supported.
'!!! lpThreadId
'Points to a 32-bit variable that receives the thread identifier

'!!!  If the function succeeds, the return value is a handle to the new thread. 
'!!!  If the function fails, the return value is NULL. To get extended error information, call GetLastError. 

Declare Function CreateThread Lib "kernel32" Alias "CreateThread" (lpThreadAttributes As long, dwStackSize As Long,_
lpStartAddress As Long,  lpParameter As long, dwCreationFlags As Long,  lpThreadId As Long) As Long


Declare Function TerminateThread Lib "kernel32" Alias "TerminateThread" ( hThread As Long,  dwExitCode As Long) As Long

Declare Function GetThreadPriority Lib "kernel32" Alias "GetThreadPriority" (hThread As Long) As Long

Declare Function SetThreadPriority Lib "kernel32" Alias "SetThreadPriority" (hThread As Long,nPriority As Long) As Long
Declare Function CloseHandle Lib "kernel32"  Alias "CloseHandle" (hObject As Long) As Long

Declare Sub Command1_Click
Declare Sub Form_Unload(Cancel As Integer)
'Declare Sub AsyncThread()
Declare Function AsyncThread (zzz as long) as long


dim lres as long 
dim fnptr1 as integer 
dim fnptr2 as integer 

bind fnptr1 to AsyncThread1 
bind fnptr2 to AsyncThread 
'bind fnptr3 to ASYNCTHREADdll

deflng zzz=123



CREATE Form AS QFORM
	Caption = "Form1"
	Width = 640
	Height = 480
	Center
	'onshow=FormShow
	
	CREATE Button1 AS QBUTTON
		Caption = "Thread"
		Left = 4
		Top = 4
		TabOrder = 8
		OnClick=Command1_Click
	END CREATE
	
	CREATE Button2 AS QBUTTON
		Caption = "No thread"
		Left = 120
		Top = 4
		TabOrder = 8
		OnClick=AsyncThread1
		
	END CREATE
	
	CREATE Button3 AS QBUTTON
		Caption = "callfunc"
		Left = 240
		Top = 4
		TabOrder = 8
		OnClick=callfuncAsyncThread
		
	END CREATE

	CREATE LogEdit AS QRICHEDIT
		align=2'albottom
		height=200
		HideScrollBars=0
		HideSelection=0
		ScrollBars=3 'ssBoth = 3  
		Wordwrap=0
		
	END CREATE
	
	
END CREATE


'*****************************
Function AsyncThread (zzz as long) as long

' 
for i=0 to 20000
	Button2.caption=str$(i)
	'doevents
	'Sleep 0.300
next i
AsyncThread=333

End Function


dim hThread As Long, ThreadID As Long

hThreadID=0
hThread=0


dim lpThreadID as long
dim PtSub as long

lpThreadID=varptr(ThreadID)
'call  AddClrString ("99:lpThreadID="+str$(lpThreadID), clred, LogEdit)
print lpThreadID
PtSub=CODEPTR(AsyncThread)
print"PtSub=";PtSub

PtSubDll=CODEPTR(AsyncThreadDll)
print"PtSubDll=";PtSubDll

PtSubZZZ=CODEPTR(AsyncThreadZZZ)
print"PtSubZZZ=";PtSubZZZ


'call  AddClrString ("101:PtSub="+str$(PtSub), clred, LogEdit)

'this.hThread=CreateThread(0,0,PtSub,0,0,PtVar)

Form.ShowModal  

'*****************************
Sub Command1_Click
'KPD-Team 1999
'URL: http://www.allapi.net/
'E-Mail: KPDTeam@Allapi.net
'After you click this button, try to move the window
'You will see that the AsyncThread-function was executed asynchronously

' Declare Function CreateThread Lib "kernel32" Alias "CreateThread" (lpThreadAttributes As long, dwStackSize As Long,_                   !!!!!!!!!
' lpStartAddress As Long, lpParameter As long, dwCreationFlags As Long,  lpThreadId As Long) As Long        !!!

deflng lpThreadAttributes=0 
deflng dwStackSize=0 
deflng lpParameter=222 
deflng dwCreationFlags=0 


'Type SECURITY_ATTRIBUTES
'nLength As Long
'lpSecurityDescriptor As Long
'bInheritHandle As Long
'End Type

dim fakesec as SECURITY_ATTRIBUTES
fakesec.nLength=24



hThread = CreateThread(&fakesec, dwStackSize, PtSub,  lpParameter, dwCreationFlags, ThreadID)
'If hThread <> 0 Then CloseHandle hThread


call  AddClrString ("148:hThread="+str$(hThread), clred, LogEdit)
call  AddClrString ("124:IdThread="+str$(ThreadID), clp, LogEdit)
call  AddClrString ("125:lpThreadID="+str$(lpThreadID), clb, LogEdit)
call  AddClrString ("126:PtSub="+str$(PtSub), clb, LogEdit)

'If hThread <> 0 Then TerminateThread hThread, 0

End Sub

'*****************************
Sub Form_Unload
'If the thread is still running, close it
If hThread <> 0 Then TerminateThread hThread, 0
End Sub



'*****************************************
Sub FormShow
 
End Sub 
'*****************************************
Sub callfuncAsyncThread
defint zzx=456
callfunc fnptr1 'This works 
 
End Sub 
'*****************************************
Sub AsyncThread1
asd= AsyncThread (234 )
call  AddClrString ("200:asd="+str$(asd), clred, LogEdit)

End Sub 
