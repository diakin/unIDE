' ----------------------------------------------------------------------------------
' MULTIPLE  CALLBACKS  UNDER  RAPIDQ            by JohnK, Paul, Warriant and Jacques
'
' CALLBACK  FORWARDER  Include  File
'
' Thanks to John who reused my forgotten Forwarder in June 2005.
' Thanks to to Paul who rewrote the CallBack Forwarder to solve the 'Win9x' bug.
'        in september 2005
' Thanks to Warriant whose optimized version relaunch the subject in august 2006
' ----------------------------------------------------------------------------------
' ----------------------------------------------------------------------------------
' How it works:
'  - the external process calls the CallBack Forwarder
'  - the callback forwarder forwards the Caller to the master callback function
'    (i.e MasterCallBack_4 in CallBack_4.Inc). It adds a first argument which is the
'    RapidQ Handle of the RapidQ Function to Forward to. (RapidQ Function Handle is
'    obtained by  Bind HandleToRqFunction To RqFunctionName
'  - the master callback use CallFunc to Call the user CallBack (RqFunctionName).
'    The Master Callback is built in the callback_X Include file.
'  The Programmer Must (example for a 4 arguments CallBack):
'    1 - Get the RapidQ Function Handle of his CallBack Function
'          DefInt hRqFunction
'          Bind hRqFunction To RqCallBackFunction
'    2 - Create a CallBack Forwarder for his CallBack by calling
'      lpfnCallBackForwarder = SetNewCallBack_4 (hRqFunction)
'      lpfnCallBackForwarder returned by SetNewCallBack_4 is the address/lpfn
'      you have to pass to the external process.
'
' **********************************************************************************
' ---- CallBack Forwader Documentation ---------------------------------------------
' The CallBack Forwarder Code (14 bytes) will be Generated in an allocated memory space,
' the pointer to that space is returned by the function.
' ForwardTo : a function pointer to our callback funtion (+ one one : first = CallBack Index you choose)
' CBIndex   : a user choosen number to identify this CallBack forwarder
' --- CallBack Forwarder Nasm Assembler code ---- Nasm List ------------------------
' ----------------------------------------------------------------------------------
'  Offset   Hexadecimal   Cycles  Memory     Mnemonic                Comments
' decimal   Code         486 CPU  access
' ----------------------------------------------------------------------------------
'    0000   58                 1       1     pop    eax                 ; eax = return address
'    0001   68DDCCBBAA         4       2     push   dword hRqFunction   ; hRqFunction 5th Argument
'    0005   50                 1       1     push   eax                 ; return address back on the stack
'    0007   B8DDCCBBAA         1       1     mov    eax, ForwardTo      ; eax = lpfnForwardTo
'    0012   FFE0               5       0     jmp    eax                 ; Goto lpfnForwardTo
' ----------------------------------------------------------------------------------
' tot: 14                     12       5
' ----------------------------------------------------------------------------------
' The job is done in 12 processor cycles and 5 memory access ! For a 2GHz processor
' it will take 6 billionth of a second + 5 memory access whose duration are unpredictable.
' ----------------------------------------------------------------------------------
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
' ----------------------------------------------------------------------------------
' **********************************************************************************
'
