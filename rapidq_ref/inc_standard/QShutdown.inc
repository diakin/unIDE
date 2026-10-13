$IFNDEF __QSHUTDOWN_INC   ' IncManager: include guard
$DEFINE __QSHUTDOWN_INC
' Quick shutdown/ logoff component for RapidQ
'  Source code from RapidQ yahoo Groups posting
'  Feb, 2006
'-----------------------start code---------------------------

$IFNDEF __WIN32API				   'windows 32 constants for sound media

Type LUID
    LowPart As Long
    HighPart As Long
End Type

Type LUID_AND_ATTRIBUTES
    ' pLuid As LUID
    LowPart as Long
    HightPart as Long
    Attributes As Long
End Type

Type TOKEN_PRIVILEGES
    PrivilegeCount As Long
    ' Privileges(1) As LUID_AND_ATTRIBUTES
    LowPart as long
    HighPart as long
    Attributes as long
End Type

$IFNDEF __RQINC2
    Declare Function ExitWindowsEx Lib "user32" Alias "ExitWindowsEx" (uFlags As Long, dwReserved As Long) As Long
    Declare Function GetCurrentProcess Lib "kernel32" Alias "GetCurrentProcess"() As Long
    Const EWX_LOGOFF = 0
    Const EWX_SHUTDOWN = 1
    Const EWX_REBOOT = 2
    Const EWX_FORCE = 4
$ENDIF      'RapidQ2 inc


$DEFINE TOKEN_ADJUST_PRIVILEGES &H20
$DEFINE TOKEN_QUERY &H8
$DEFINE SE_PRIVILEGE_ENABLED &H2

Declare Function OpenProcessToken Lib "advapi32" Alias "OpenProcessToken" _
    (ProcessHandle As Long, _
    DesiredAccess As Long, _
    TokenHandle As Long) As Long

Declare Function LookupPrivilegeValue Lib "advapi32" Alias "LookupPrivilegeValueA" _
    (lpSystemName As String, _
    lpName As String, _
    lpLuid As LUID) As Long

Declare Function AdjustTokenPrivileges Lib "advapi32" Alias "AdjustTokenPrivileges" _
    (TokenHandle As Long, _
    DisableAllPrivileges As Long, _
    NewState As TOKEN_PRIVILEGES, _
    BufferLength As Long, _
    PreviousState As TOKEN_PRIVILEGES, _
    ReturnLength As Long) As Long


$ENDIF      'windows.inc

TYPE QShutDown EXTENDS QOBJECT
PRIVATE:
    ProcHandle As Long
    MyFlag As Long

SUB DoShutDown
    ' Grab the shutdown privilege - else reboot will fail
    DIM Thndl As Long
    DIM MyLUID As LUID
    DIM MyPriv As TOKEN_PRIVILEGES, MyNewPriv As TOKEN_PRIVILEGES
    DIM ret as long
    DIM pdword as integer

    This.ProcHandle = GetCurrentProcess()
    ret = OpenProcessToken(This.ProcHandle, TOKEN_ADJUST_PRIVILEGES Or TOKEN_QUERY, @Thndl)
    ret = LookupPrivilegeValue("", "SeShutdownPrivilege", MyLUID)
    MyPriv.PrivilegeCount = 1
    MyPriv.Attributes = SE_PRIVILEGE_ENABLED
    MyPriv.LowPart = MyLUID.LowPart
    MyPriv.HighPart = MyLUID.HighPart
    ' Now to set shutdown privilege for my app

    pdword = 4 + (12 * MyNewPriv.PrivilegeCount)
    ret = AdjustTokenPrivileges(Thndl, False, MyPriv, 4 + (12 * MyPriv.PrivilegeCount), MyNewPriv,@pdword)

    ' Do the required action
    Ret = ExitWindowsEx(This.MyFlag, 0) ' inc2026: This.MyFlag вместо MyFlag: внутри метода поле пишется через This или имя типа (глава 10.3), без него MyFlag - другая (необъявленная) переменная, а поле MyFlag не используется; так в копии компонента в rapidq2.inc (строки 7777-7797)
End Sub

PUBLIC:
    SUB ShutDown
        This.MyFlag = EWX_SHUTDOWN ' inc2026: This.MyFlag вместо MyFlag: см. строку 89 (без This поле не меняется)
        This.DoShutDown
    END SUB

    SUB ShutDownForce
        This.MyFlag = EWX_FORCE or EWX_SHUTDOWN ' inc2026: This.MyFlag вместо MyFlag: см. строку 89 (без This поле не меняется)
        This.DoShutDown
    END SUB

    SUB LogOff
        This.MyFlag = EWX_LOGOFF ' inc2026: This.MyFlag вместо MyFlag: см. строку 89 (без This поле не меняется)
        This.DoShutDown
    END SUB

    SUB Reboot
        This.MyFlag = EWX_REBOOT ' inc2026: This.MyFlag вместо MyFlag: см. строку 89 (без This поле не меняется)
        This.DoShutDown
    END SUB

    CONSTRUCTOR
        MyFlag = EWX_LOGOFF
    END CONSTRUCTOR
END TYPE
$ENDIF   ' IncManager: __QSHUTDOWN_INC
