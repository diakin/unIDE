'
' ----------------------------------------------------------------------------------
' MULTIPLE 8 ARGUMENTS CALLBACKS  UNDER  RAPIDQ        INCLUDE            by Jacques
' (not tested : replaced _4 by _8 and added the required ArgN in pasted
' CallBack_4.Inc. It Should work)
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
$IFNDEF _CALLBACK_8
    $DEFINE _CALLBACK_8
    Declare Function MasterCallBack_8 (hFunction As Long, Arg1 As Long, Arg2 As Long, Arg3 As Long, Arg4 As long, Arg5 As long, Arg6 As long, Arg7 As long, Arg8 As long) As Long
    Declare Function FuncBind_8 (Arg1 As Long, Arg2 As Long, Arg3 As Long, Arg4 As long, Arg5 As long, Arg6 As long, Arg7 As long, Arg8 As long) As Long
    DefInt lpCallBack_8  = CodePtr(MasterCallBack_8)

    Function MasterCallBack_8 (hFunction As Long, Arg1 As Long, Arg2 As Long, Arg3 As Long, Arg4 As Long, Arg5 As long, Arg6 As long, Arg7 As long, Arg8 As long) As Long
        DefInt hBind
        Bind hBind To FuncBind_8
        hBind = hFunction
        Result = CallFunc (hBind, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8)
    End Function

    Function SetNewCallBack_8 (hFunction As Long) As Long
        Result = SetNewFwToCallBack (lpCallBack_8, hFunction)
    End Function
$ENDIF
' ----------------------------------------------------------------------------------
'
