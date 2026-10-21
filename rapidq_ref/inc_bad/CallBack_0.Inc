'
' ----------------------------------------------------------------------------------
' MULTIPLE 0 ARGUMENTS CALLBACKS  UNDER  RAPIDQ        INCLUDE            by Jacques
' (not tested : replaced _4 by _0 and deleted the unnecessary ArgN in pasted
' CallBack_4.Inc. It Should work ?)
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
        .WriteNum(&Forwardto  , 4)    ' ... ForwardTo
        .WriteNum(&HE0FF      , 2)    ' jmp eax
        memcpy (ptrForwarder, .Pointer, 14)
    END WITH
    Result = ptrForwarder
END FUNCTION
$ENDIF
' **********************************************************************************
$IFNDEF _CALLBACK_0
    $DEFINE _CALLBACK_0
    Declare Function MasterCallBack_0 (hFunction As Long) As Long
    Declare Function FuncBind_0 (hFunction As Long) As Long  ' Bind dont work with no Arg function
    DefInt lpCallBack_0  = CodePtr(MasterCallBack_0)

    Function MasterCallBack_0 (hFunction As Long) As Long
        DefInt hBind = hFunction
        Bind hBind To FuncBind_0
        Result = CallFunc (hBind, hBind)
    End Function

    Function SetNewCallBack_0 (hFunction As Long) As Long
        Result = SetNewFwToCallBack (lpCallBack_0, hFunction)
    End Function
$ENDIF
' ----------------------------------------------------------------------------------
'
