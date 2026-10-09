'
' ----------------------------------------------------------------------------
' SET NEW WINDOW PROCEDURE     MANY CALLBACK     TURN AROUND        by Jacques
'
'!!! NO INDEX, AS MANY NEW WNDPROC AS YOU WANT                       MUCH EASIERS
'
' Thanks Warriant for relaunching the subject
' August 13th, 2006
' ----------------------------------------------------------------------------

$IFNDEF _NEWWNDPROC
$DEFINE _NEWWNDPROC
$IFNDEF _CALLBACK_4
    $DEFINE _CALLBACK_4
    Declare Function MasterCallBack_4 (hFunction As Long, Arg1 As Long, Arg2 As Long, Arg3 As Long, Arg4 As long) As Long
    Declare Function FuncBind_4 (Arg1 As Long, Arg2 As Long, Arg3 As Long, Arg4 As long) As Long
    DefInt lpCallBack_4 = CodePtr(MasterCallBack_4)
'
    Function MasterCallBack_4 (hFunction As Long, Arg1 As Long, Arg2 As Long, Arg3 As Long, Arg4 As Long) As Long
        DefInt hBind
        Bind hBind To FuncBind_4
        hBind = hFunction
        Result = CallFunc (hBind, Arg1, Arg2, Arg3, Arg4)
    End Function
$ENDIF
' ==== CALLBACK FORWARDER ===========================================
Declare Function NWP_GetProcessHeap Lib "kernel32" Alias "GetProcessHeap" () As Long
Declare Function NWP_HeapAlloc Lib "kernel32" Alias "HeapAlloc" (ByVal hHeap As Long, _
                                          ByVal dwFlags As Long, ByVal dwBytes As Long) As Long
DECLARE FUNCTION NWP_SetWindowLong LIB "USER32" ALIAS "SetWindowLongA" (hWnd AS LONG, nIndex AS LONG, dwNewLong AS LONG) AS LONG
' -------------------------------------------------------------------
FUNCTION SetNewWndProc (ObjectHandle AS LONG, hFunction AS LONG) AS LONG
    DEFLNG hProcessHeap = NWP_GetProcessHeap
    DEFLNG ptrForwarder = NWP_HeapAlloc (hProcessHeap, 12, 14)
    DIM mTmp AS QMEMORYSTREAM
    WITH mTmp
        .Size = 14
        .Position = 0
        .WriteNum(&H58           , 1)    ' pop Eax
        .WriteNum(&H68           , 1)    ' push ...
        .WriteNum(hFunction      , 4)    ' ... hFunction
        .WriteNum(&H50           , 1)    ' push eax
        .WriteNum(&HB8           , 1)    ' mov  eax, ...
        .WriteNum(lpCallBack_4   , 4)    ' ... ForwardTo
        .WriteNum(&HE0FF         , 2)    ' jmp eax
        memcpy (ptrForwarder  , .Pointer, 14)
    END WITH
    Result = NWP_SetWindowLong (ObjectHandle, -4, ptrForwarder)
END FUNCTION
' ==== END CALLBACK FORWARDER =======================================
$ENDIF
'
