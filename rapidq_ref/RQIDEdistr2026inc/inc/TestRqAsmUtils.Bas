'
' Test RqAsmUtils.Inc    July 05nd, 2004
'
$Include "RqAsmUtils.Inc"   ' The Same as the Dll AsmUtils.dll ... maybe with error exception on CallAddress/Pointer
'
$ESCAPECHARS ON
$TYPECHECK ON
$INCLUDE "RAPIDQ.INC"
'
Declare Function GetTickCount Lib "kernel32" Alias "GetTickCount" () As Long
' -----------------------------------------------
' Function to Be Called by CallAddressManyArgs and CallPointerManyArgs
DefStr sMsgHeader
Sub ShowMsg (A As Long, B As Long, c As Long, D As Long)
    ShowMessage ( sMsgHeader & "\nA=" & Hex$(A)& "\nB=" & Hex$(B)& "\nC=" & Hex$(C) & "\nD=" & Hex$(D))
End Sub
'
Sub ShowMsg3Args (A As Long, B As Long, c As Long)
    ShowMessage ( sMsgHeader & "\nA=" & Hex$(A)& "\nB=" & Hex$(B)& "\nC=" & Hex$(C))
End Sub
'
Sub ShowMsgNoArg ()
    ShowMessage (sMsgHeader)
End Sub
'
' -----------------------------------------------
DefInt iAddress, iPtr, iPtr0, iPtr1, iPtr2, ptrArray, N
'
' The Array that will contain the passed argument
' (see CallAddressManyArgs and CallPointerManyArgs Code in RqAsmUtils.Inc)
Dim myArray(5) As Integer
' The pointer to the Function to be called by CallAddressManyArgs an CallPointerManyArgs
iPtr = CodePtr(ShowMsg)
' set the values of the arguments (used too to test the Reads functions of the RqAsmUtils.Inc)
myArray(0) = 4                      ' 4 arguments
myArray(1) = &HFFFF8000             ' Argument 1
myArray(2) = &HFFFFFF40             ' Argument 2
myArray(3) = &H12345678             ' Argument 3
myArray(4) = &H44444444             ' Argument 4
'
ptrArray = VarPtr(myArray(0))
'
iptr0 = VarPtr(myArray(0))
iPtr1 = VarPtr(myArray(1))
iPtr2 = VarPtr(myArray(2))
'
Print "Sub showMsg  CodePtr = ";iPtr
Print "myArray(0)  ptrArray = ";ptrArray
Print
' Tests The Read at Address functions of the Dll
Print "RqAsmUtils Read DWORD at Address = ";ReadDWordAtAddress(iPtr0)
Print "RqAsmUtils Read WORD  at Address = ";ReadWordAtAddress(iPtr1)
Print "RqAsmUtils Read BYTE  at Address = ";ReadByteAtAddress(iPtr2)
' Test the read at Pointer functions of the Dll
Print "RqAsmUtils Read DWORD at Pointer = ";ReadDWordAtPointer(VarPtr(iPtr0))
Print "RqAsmUtils Read WORD  at Pointer = ";ReadWordAtPointer(VarPtr(iPtr1))
Print "RqAsmUtils Read BYTE  at Pointer = ";ReadByteAtPointer(VarPtr(iPtr2))
'
' Calls Sub ShowMsg via CallAddressManyArgs in RqAsmUtils.Inc
sMsgHeader = "Sub Called with CallAddressManyArgs of RqAsmUtils.Inc"
myArray(0) = 4                      ' 4 arguments to pass
myArray(1) = &HFFFF8000             ' Argument 1
myArray(2) = &HFFFFFF40             ' Argument 2
myArray(3) = &H12345678             ' Argument 3
myArray(4) = &H44444444             ' Argument 4
CallAddressManyArgs(iPtr, ptrArray)
'
' Calls Sub ShowMsg via CallPointerManyArgs in RqAsmUtils.Inc
sMsgHeader = "Sub Called With CallPointerManyArgs  RqAsmUtils.Inc"
myArray(0) = 4                      ' 4 arguments to pass
myArray(1) = &H11111111             ' Argument 1
myArray(2) = &H22222222             ' Argument 2
myArray(3) = &H33333333             ' Argument 3
myArray(4) = &H44444444             ' Argument 4
CallPointerManyArgs(VarPtr(iPtr), ptrArray)
'
' Calls Sub ShowMsg via API CallWindowProcA in user32.dll
sMsgHeader = "Sub Called With API CallWindowProcA in user32.dll"
CallAsmProc(iPtr, 111, 222, 333, 444)
'
' Calls Sub ShowMsg via CallAddressThreeArgs in RqAsmUtils.Inc
iPtr =  CodePtr(ShowMsg3Args)
sMsgHeader = "Sub Called With CallAddressThreeArgs in RqAsmUtils.Inc"
CallAsmProc(iPtr, 111, 222, 333, 444)
'
' Calls Sub ShowMsg usual way :)
sMsgHeader = "Sub Called as usually in RQ :)"
ShowMsg(111, 222, 333, 444)
'
' call a SUB with no argument via CallAddressNoArg and CallPointerNoArg
iPtr = CodePtr(ShowMsgNoArg)
Print "iptr ShowMsgNoArg = ";iPtr
sMsgHeader = "Sub ShowMsgNoArg with No CallAddressNoArg from RqAsmUtils.Inc "
CallAddressNoArg(iPtr)  ' There to OneArg, TwoArgs, ThreArgs for CallAddress... and Call Pointer
'
sMsgHeader = "Sub ShowMsgNoArg with No CallPointerNoArg from RqAsmUtils.Inc "
CallPointerNoArg(VarPtr(iPtr)) ' There to OneArg, TwoArgs, ThreArgs for CallAddress... and Call Pointer
'
' Call sub with no Argument via CallAddressManyArgs with myArray(0) = 0
myArray(0) = 0   ' Zero Arg
sMsgHeader = "Sub No Arg Called with CallAddressManyArgs of RqAsmUtils.Inc"
CallAddressManyArgs(iPtr, ptrArray)
'
' Call sub with no Argument via CallPointerManyArgs with myArray(0) = 0
sMsgHeader = "Sub No Arg Called With CallPointerManyArgs  RqAsmUtils.Inc"
CallPointerManyArgs(VarPtr(iPtr), ptrArray)
'
' -------------------------------------------------------------
' EXIT CONSOLE
' ------------
DefStr sExit
Input "\n\n                    CR to QUIT \n\n", sExit
Application.Terminate
End
'
