'
' ----------------------------------------------------------------------------------
' MULTIPLE 4 ARGUMENTS CALLBACKS  UNDER  RAPIDQ        INCLUDE            by Jacques
'
'
' Thanks to JohnK who found this turn around and to Paul who rewrote the CallBack
' Forwarder to solve the 'Win9x' bug.
' September 25th, 2005
' Thanks to Warriant relaunched the subject in August 2006
' August 13th, 2006
' ----------------------------------------------------------------------------------
' Documentation in CallBack.Htm
'
' **********************************************************************************
' CALLBACK FORWARDER CODE
' -----------------------
$IFNDEF CALLBACK_FORWARDER
$DEFINE CALLBACK_FORWARDER
Declare Function FWCB_GetProcessHeap Lib "kernel32" Alias "GetProcessHeap" () As Long
Declare Function FWCB_HeapAlloc Lib "kernel32" Alias "HeapAlloc" (ByVal hHeap As Long, ByVal dwFlags As Long, ByVal dwBytes As Long) As Long
'
' ================================================================
FUNCTION SetNewFwToCallBack (ForwardTo AS LONG, hFunction AS LONG) AS LONG
    DEFLNG hProcessHeap = FWCB_GetProcessHeap
    DEFLNG ptrForwarder = FWCB_HeapAlloc (hProcessHeap, 12, 14)
    DIM mTmp AS QMEMORYSTREAM
    WITH mTmp
        .Size = 14
        .Position = 0
        .WriteNum(&H58        , 1)    ' pop Eax
        .WriteNum(&H68        , 1)    ' push ...
        .WriteNum(hFunction   , 4)    ' ... hRqFunction
        .WriteNum(&H50        , 1)    ' push eax
        .WriteNum(&HB8        , 1)    ' mov  eax, ...
        .WriteNum(Forwardto   , 4)    ' ... ForwardTo
        .WriteNum(&HE0FF      , 2)    ' jmp eax
        memcpy (ptrForwarder, .Pointer, 14)
    END WITH
    Result = ptrForwarder
END FUNCTION
$ENDIF
' **********************************************************************************
$IFNDEF _CALLBACK_4
    $DEFINE _CALLBACK_4
    Declare Function MasterCallBack_4 (hFunction As Long, Arg1 As Long, Arg2 As Long, Arg3 As Long, Arg4 As long) As Long
    Declare Function FuncBind_4 (Arg1 As Long, Arg2 As Long, Arg3 As Long, Arg4 As long) As Long
    DefInt lpCallBack_4 = CodePtr(MasterCallBack_4)

    Function MasterCallBack_4 (hFunction As Long, Arg1 As Long, Arg2 As Long, Arg3 As Long, Arg4 As Long) As Long
        DefInt hBind
        Bind hBind TO FuncBind_4
        hBind = hFunction
        Result = CallFunc (hBind, Arg1, Arg2, Arg3, Arg4)
    End Function

    Function SetNewCallBack_4 (hFunction As Long) As Long
        Result = SetNewFwToCallBack (lpCallBack_4, hFunction)
    End Function
$ENDIF
' ----------------------------------------------------------------------------------
'
