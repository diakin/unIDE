'=======================================================
' Type Objet
' Classe QThread version 1.0
'=======================================================
Const ProcessLow=-2
Const ProcessBelowNormal=-1
Const ProcessNormal=0
Const ProcessHight=2
Const ProcessAboveNormal=1
Const ProcessTimeCritical=15
Const ProcessIdle=-15
      

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

Declare Function CreateThread Lib "kernel32" Alias "CreateThread" (lpThreadAttributes As long, dwStackSize As Long,_
lpStartAddress As Long, lpParameter As long, dwCreationFlags As Long, lpThreadId As Long) As Long




Declare Function TerminateThread Lib "kernel32" Alias "TerminateThread" (ByVal hThread As Long, ByVal dwExitCode As Long) As Long

Declare Function GetThreadPriority Lib "kernel32" Alias "GetThreadPriority" (hThread As Long) As Long

Declare Function SetThreadPriority Lib "kernel32" Alias "SetThreadPriority" (hThread As Long,nPriority As Long) As Long



declare sub OnThread_event

Type QThread extends QObject
  Private:
    IdThread as long
    hThread as long
  Public:
    OnThread as Event(OnThread_event)
    Priority as long Property set SetPriority
  
    '==========================================
    ' proprietй prioritй Thread
    '==========================================  
    Property set SetPriority(priority as long)
      this.priority=priority
    end property

  Private:
    '==========================================
    ' mйthode appelle Thread
    '==========================================  
    Sub Thread
      if This.OnThread<>0 then CALLFUNC this.OnThread
    End Sub
    
  Public:
    '==========================================
    ' mйthode exйcution Thread
    '==========================================  
    Sub Open
      dim PtVar as long
      dim PtSub as long
    
       if this.hThread<>0 then TerminateThread(this.hThread,0)
       PtVar=varptr(this.IdThread)
       PtSub=CODEPTR(this.Thread)
       this.hThread=CreateThread(0,0,PtSub,0,0,PtVar)
       SetThreadPriority(this.hThread,this.Priority) 
    End Sub

    '==========================================
    ' mйthode fin Thread
    '==========================================  
    Sub Close
      if this.hThread<>0 then TerminateThread(this.hThread,0)
    End Sub

    Constructor
      priority=0
      IdThread=0
      hThread=0    
    End Constructor  
End Type


