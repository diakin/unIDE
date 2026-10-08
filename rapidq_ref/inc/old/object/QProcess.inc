'=======================================================
' Type Objet
' Classe QProcess version 1.0
'=======================================================
Const ProcessLow=-2
Const ProcessBelowNormal=-1
Const ProcessNormal=0
Const ProcessHight=2
Const ProcessAboveNormal=1
Const ProcessTimeCritical=15
Const ProcessIdle=-15
      
Declare Function CreateProcess Lib "kernel32" Alias "CreateThread" (lpThreadAttributes As long, ByVal dwStackSize As Long, lpStartAddress As Long, lpParameter As long, ByVal dwCreationFlags As Long, lpThreadId As Long) As Long
Declare Function TerminateProcess Lib "kernel32" Alias "TerminateThread" (ByVal hThread As Long, ByVal dwExitCode As Long) As Long
Declare Function GetProcessPriority Lib "kernel32" Alias "GetThreadPriority" (hThread As Long) As Long
Declare Function SetProcessPriority Lib "kernel32" Alias "SetThreadPriority" (hThread As Long,nPriority As Long) As Long
declare sub OnProcess_event

Type QProcess extends QObject
  Private:
    IdProcess as long
    hProcess as long
  Public:
    OnProcess as Event(OnProcess_event)
    Priority as long Property set SetPriority
  
    '==========================================
    ' proprietй prioritй process
    '==========================================  
    Property set SetPriority(priority as long)
      this.priority=priority
    end property

  Private:
    '==========================================
    ' mйthode appelle process
    '==========================================  
    Sub Process
      if This.OnProcess<>0 then CALLFUNC this.OnProcess
    End Sub
    
  Public:
    '==========================================
    ' mйthode exйcution process
    '==========================================  
    Sub Open
      dim PtVar as long
      dim PtSub as long
    
       if this.hProcess<>0 then TerminateProcess(this.hProcess,0)
       PtVar=varptr(this.IdProcess)
       PtSub=CODEPTR(this.Process)
       this.hProcess=CreateProcess(0,0,PtSub,0,0,PtVar)
       SetProcessPriority(this.hProcess,this.Priority) 
    End Sub

    '==========================================
    ' mйthode fin process
    '==========================================  
    Sub Close
      if this.hProcess<>0 then TerminateProcess(this.hProcess,0)
    End Sub

    Constructor
      priority=0
      IdProcess=0
      hProcess=0    
    End Constructor  
End Type


