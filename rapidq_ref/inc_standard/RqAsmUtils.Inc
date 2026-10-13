$IFNDEF __RQASMUTILS_INC   ' IncManager: include guard
$DEFINE __RQASMUTILS_INC
'
DECLARE FUNCTION CallAsmProc LIB "user32" ALIAS "CallWindowProcA" _
            (Proc AS LONG, A1 AS LONG, A2 AS LONG, A3 AS LONG, _
             A4 AS LONG) AS LONG
'
' ============================================================
' ----- START ASM CallAddressManyArgs -----
DefByte CallAddressManyArgsArray (0 To 67) = _
   { _
    &HC8, &H00, &H00, &H00, &H56, &H53, &H8B, &H75, &H0C, &H81,  _
    &HFE, &H00, &H00, &H00, &H00, &H74, &H28, &H8B, &H06, &HC1,  _
    &HE0, &H02, &H3D, &H00, &H00, &H00, &H00, &H74, &H0B, &H8B,  _
    &H1C, &H06, &H53, &H2D, &H04, &H00, &H00, &H00, &H75, &HF5,  _
    &H8B, &H45, &H08, &H3D, &H00, &H00, &H00, &H00, &H74, &H07,  _
    &HFF, &HD0, &HE9, &H05, &H00, &H00, &H00, &HB8, &H00, &H00,  _
    &H00, &H00, &H5B, &H5E, &HC9, &HC2, &H10, &H00 _
   }
' ----- END ASM CallAddressManyArgs -----
'
' ----- POINTER to use In CallAsmProc -----
'       A Bit Faster than Calling CallAddressManyArgs
DefInt ptrCallAddressManyArgs
ptrCallAddressManyArgs = VarPtr (CallAddressManyArgsArray(0))
'
' ----- RQ CALL CallAddressManyArgs -----
Function CallAddressManyArgs (address As Long, ptrStructArg As Long) As Long
    Result = CallAsmProc (ptrCallAddressManyArgs, address, ptrStructArg, 0, 0)
End Function
'
' ============================================================
'
' ============================================================
' ----- START ASM CallPointerManyArgs -----
DefByte CallPointerManyArgsArray (0 To 76) = _
   { _
    &HC8, &H00, &H00, &H00, &H56, &H53, &H8B, &H75, &H0C, &H81,  _
    &HFE, &H00, &H00, &H00, &H00, &H74, &H31, &H8B, &H06, &HC1,  _
    &HE0, &H02, &H3D, &H00, &H00, &H00, &H00, &H74, &H0B, &H8B,  _
    &H1C, &H06, &H53, &H2D, &H04, &H00, &H00, &H00, &H75, &HF5,  _
    &H8B, &H45, &H08, &H3D, &H00, &H00, &H00, &H00, &H74, &H10,  _
    &H8B, &H00, &H3D, &H00, &H00, &H00, &H00, &H74, &H07, &HFF,  _
    &HD0, &HE9, &H05, &H00, &H00, &H00, &HB8, &H00, &H00, &H00,  _
    &H00, &H5B, &H5E, &HC9, &HC2, &H10, &H00 _
   }
' ----- END ASM CallPointerManyArgs -----
'
' ----- POINTER to use In CallAsmProc -----
'       A Bit Faster than Calling CallPointerManyArgs
DefInt ptrCallPointerManyArgs
ptrCallPointerManyArgs = VarPtr (CallPointerManyArgsArray(0))
'
' ----- RQ CALL CallPointerManyArgs -----
Function CallPointerManyArgs (pointer As Long, ptrStructArg As Long) As Long
    Result = CallAsmProc (ptrCallPointerManyArgs, pointer, ptrStructArg, 0, 0)
End Function
'
' ============================================================
'
' ============================================================
' ----- START ASM CallAddressNoArg -----
DefByte CallAddressNoArgArray (0 To 19) = _
   { _
    &HC8, &H00, &H00, &H00, &H8B, &H45, &H08, &H3D, &H00, &H00,  _
    &H00, &H00, &H74, &H02, &HFF, &HD0, &HC9, &HC2, &H10, &H00 _
   }
' ----- END ASM CallAddressNoArg -----
'
' ----- POINTER to use In CallAsmProc -----
'       A Bit Faster than Calling CallAddressNoArg
DefInt ptrCallAddressNoArg
ptrCallAddressNoArg = VarPtr (CallAddressNoArgArray(0))
'
' ----- RQ CALL CallAddressNoArg -----
Function CallAddressNoArg (address As Long) As Long
    Result = CallAsmProc (ptrCallAddressNoArg, address, 0, 0, 0)
End Function
'
' ============================================================
'
' ============================================================
' ----- START ASM CallPointerNoArg -----
DefByte CallPointerNoArgArray (0 To 28) = _
   { _
    &HC8, &H00, &H00, &H00, &H8B, &H45, &H08, &H3D, &H00, &H00,  _
    &H00, &H00, &H74, &H0B, &H8B, &H00, &H3D, &H00, &H00, &H00,  _
    &H00, &H74, &H02, &HFF, &HD0, &HC9, &HC2, &H10, &H00 _
   }
' ----- END ASM CallPointerNoArg -----
'
' ----- POINTER to use In CallAsmProc -----
'       A Bit Faster than Calling CallPointerNoArg
DefInt ptrCallPointerNoArg
ptrCallPointerNoArg = VarPtr (CallPointerNoArgArray(0))
'
' ----- RQ CALL CallPointerNoArg -----
Function CallPointerNoArg (pointer As Long) As Long
    Result = CallAsmProc (ptrCallPointerNoArg, pointer, 0, 0, 0)
End Function
'
' ============================================================
'
' ============================================================
' ----- START ASM CallAddressOneArg -----
DefByte CallAddressOneArgArray (0 To 22) = _
   { _
    &HC8, &H00, &H00, &H00, &H8B, &H45, &H08, &H3D, &H00, &H00,  _
    &H00, &H00, &H74, &H05, &HFF, &H75, &H0C, &HFF, &HD0, &HC9,  _
    &HC2, &H10, &H00 _
   }
' ----- END ASM CallAddressOneArg -----
'
' ----- POINTER to use In CallAsmProc -----
'       A Bit Faster than Calling CallAddressOneArg
DefInt ptrCallAddressOneArg
ptrCallAddressOneArg = VarPtr (CallAddressOneArgArray(0))
'
' ----- RQ CALL CallAddressOneArg -----
Function CallAddressOneArg (address As Long, arg1 As Long) As Long
    Result = CallAsmProc (ptrCallAddressOneArg, address, arg1, 0, 0)
End Function
'
' ============================================================
'
' ============================================================
' ----- START ASM CallPointerOneArg -----
DefByte CallPointerOneArgArray (0 To 31) = _
   { _
    &HC8, &H00, &H00, &H00, &H8B, &H45, &H08, &H3D, &H00, &H00,  _
    &H00, &H00, &H74, &H0E, &H8B, &H00, &H3D, &H00, &H00, &H00,  _
    &H00, &H74, &H05, &HFF, &H75, &H0C, &HFF, &HD0, &HC9, &HC2,  _
    &H10, &H00 _
   }
' ----- END ASM CallPointerOneArg -----
'
' ----- POINTER to use In CallAsmProc -----
'       A Bit Faster than Calling CallPointerOneArg
DefInt ptrCallPointerOneArg
ptrCallPointerOneArg = VarPtr (CallPointerOneArgArray(0))
'
' ----- RQ CALL CallPointerOneArg -----
Function CallPointerOneArg (pointer As Long, arg1 As Long) As Long
    Result = CallAsmProc (ptrCallPointerOneArg, pointer, arg1, 0, 0)
End Function
'
' ============================================================
'
' ============================================================
' ----- START ASM CallAddressTwoArgs -----
DefByte CallAddressTwoArgsArray (0 To 25) = _
   { _
    &HC8, &H00, &H00, &H00, &H8B, &H45, &H08, &H3D, &H00, &H00,  _
    &H00, &H00, &H74, &H08, &HFF, &H75, &H10, &HFF, &H75, &H0C,  _
    &HFF, &HD0, &HC9, &HC2, &H10, &H00 _
   }
' ----- END ASM CallAddressTwoArgs -----
'
' ----- POINTER to use In CallAsmProc -----
'       A Bit Faster than Calling CallAddressTwoArgs
DefInt ptrCallAddressTwoArgs
ptrCallAddressTwoArgs = VarPtr (CallAddressTwoArgsArray(0))
'
' ----- RQ CALL CallAddressTwoArgs -----
Function CallAddressTwoArgs (address As Long, arg1 As Long, arg2 As Long) As Long
    Result = CallAsmProc (ptrCallAddressTwoArgs, address, arg1, arg2, 0)
End Function
'
' ============================================================
'
' ============================================================
' ----- START ASM CallPointerTwoArgs -----
DefByte CallPointerTwoArgsArray (0 To 34) = _
   { _
    &HC8, &H00, &H00, &H00, &H8B, &H45, &H08, &H3D, &H00, &H00,  _
    &H00, &H00, &H74, &H11, &H8B, &H00, &H3D, &H00, &H00, &H00,  _
    &H00, &H74, &H08, &HFF, &H75, &H10, &HFF, &H75, &H0C, &HFF,  _
    &HD0, &HC9, &HC2, &H10, &H00 _
   }
' ----- END ASM CallPointerTwoArgs -----
'
' ----- POINTER to use In CallAsmProc -----
'       A Bit Faster than Calling CallPointerTwoArgs
DefInt ptrCallPointerTwoArgs
ptrCallPointerTwoArgs = VarPtr (CallPointerTwoArgsArray(0))
'
' ----- RQ CALL CallPointerTwoArgs -----
Function CallPointerTwoArgs (pointer As Long, arg1 As Long, arg2 As Long) As Long
    Result = CallAsmProc (ptrCallPointerTwoArgs, pointer, arg1, arg2, 0)
End Function
'
' ============================================================
'
' ============================================================
' ----- START ASM CallAddressThreeArgs -----
DefByte CallAddressThreeArgsArray (0 To 28) = _
   { _
    &HC8, &H00, &H00, &H00, &H8B, &H45, &H08, &H3D, &H00, &H00,  _
    &H00, &H00, &H74, &H0B, &HFF, &H75, &H14, &HFF, &H75, &H10,  _
    &HFF, &H75, &H0C, &HFF, &HD0, &HC9, &HC2, &H10, &H00 _
   }
' ----- END ASM CallAddressThreeArgs -----
'
' ----- POINTER to use In CallAsmProc -----
'       A Bit Faster than Calling CallAddressThreeArgs
DefInt ptrCallAddressThreeArgs
ptrCallAddressThreeArgs = VarPtr (CallAddressThreeArgsArray(0))
'
' ----- RQ CALL CallAddressThreeArgs -----
Function CallAddressThreeArgs (address As Long, arg1 As Long, arg2 As Long, arg3 As Long) As Long
    Result = CallAsmProc (ptrCallAddressThreeArgs, address, arg1, arg2, arg3)
End Function
'
' ============================================================
'
' ============================================================
' ----- START ASM CallPointerThreeArgs -----
DefByte CallPointerThreeArgsArray (0 To 37) = _
   { _
    &HC8, &H00, &H00, &H00, &H8B, &H45, &H08, &H3D, &H00, &H00,  _
    &H00, &H00, &H74, &H14, &H8B, &H00, &H3D, &H00, &H00, &H00,  _
    &H00, &H74, &H0B, &HFF, &H75, &H14, &HFF, &H75, &H10, &HFF,  _
    &H75, &H0C, &HFF, &HD0, &HC9, &HC2, &H10, &H00 _
   }
' ----- END ASM CallPointerThreeArgs -----
'
' ----- POINTER to use In CallAsmProc -----
'       A Bit Faster than Calling CallPointerThreeArgs
DefInt ptrCallPointerThreeArgs
ptrCallPointerThreeArgs = VarPtr (CallPointerThreeArgsArray(0))
'
' ----- RQ CALL CallPointerThreeArgs -----
Function CallPointerThreeArgs (pointer As Long, arg1 As Long, arg2 As Long, arg3 As Long) As Long
    Result = CallAsmProc (ptrCallPointerThreeArgs, pointer, arg1, arg2, arg3)
End Function
'
' ============================================================
'
' ============================================================
' ----- START ASM ReadDWordAtAddress -----
DefByte ReadDWordAtAddressArray (0 To 12) = _
   { _
    &HC8, &H00, &H00, &H00, &H8B, &H45, &H08, &H8B, &H00, &HC9,  _
    &HC2, &H10, &H00 _
   }
' ----- END ASM ReadDWordAtAddress -----
'
' ----- POINTER to use In CallAsmProc -----
'       A Bit Faster than Calling ReadDWordAtAddress
DefInt ptrReadDWordAtAddress
ptrReadDWordAtAddress = VarPtr (ReadDWordAtAddressArray(0))
'
' ----- RQ CALL ReadDWordAtAddress -----
Function ReadDWordAtAddress (address As Long) As Long
    Result = CallAsmProc (ptrReadDWordAtAddress, address, 0, 0, 0)
End Function
'
' ============================================================
'
' ============================================================
' ----- START ASM ReadWordAtAddress -----
DefByte ReadWordAtAddressArray (0 To 20) = _
   { _
    &HC8, &H00, &H00, &H00, &H56, &H8B, &H75, &H08, &HB8, &H00,  _
    &H00, &H00, &H00, &H66, &H8B, &H06, &H5E, &HC9, &HC2, &H10,  _
    &H00 _
   }
' ----- END ASM ReadWordAtAddress -----
'
' ----- POINTER to use In CallAsmProc -----
'       A Bit Faster than Calling ReadWordAtAddress
DefInt ptrReadWordAtAddress
ptrReadWordAtAddress = VarPtr (ReadWordAtAddressArray(0))
'
' ----- RQ CALL ReadWordAtAddress -----
Function ReadWordAtAddress (address As Long) As Long
    Result = CallAsmProc (ptrReadWordAtAddress, address, 0, 0, 0)
End Function
'
' ============================================================
'
' ============================================================
' ----- START ASM ReadByteAtAddress -----
DefByte ReadByteAtAddressArray (0 To 19) = _
   { _
    &HC8, &H00, &H00, &H00, &H56, &H8B, &H75, &H08, &HB8, &H00,  _
    &H00, &H00, &H00, &H8A, &H06, &H5E, &HC9, &HC2, &H10, &H00 _
   }
' ----- END ASM ReadByteAtAddress -----
'
' ----- POINTER to use In CallAsmProc -----
'       A Bit Faster than Calling ReadByteAtAddress
DefInt ptrReadByteAtAddress
ptrReadByteAtAddress = VarPtr (ReadByteAtAddressArray(0))
'
' ----- RQ CALL ReadByteAtAddress -----
Function ReadByteAtAddress (address As Long) As Long
    Result = CallAsmProc (ptrReadByteAtAddress, address, 0, 0, 0)
End Function
'
' ============================================================
'
' ============================================================
' ----- START ASM ReadDWordAtPointer -----
DefByte ReadDWordAtPointerArray (0 To 14) = _
   { _
    &HC8, &H00, &H00, &H00, &H8B, &H45, &H08, &H8B, &H00, &H8B,  _
    &H00, &HC9, &HC2, &H10, &H00 _
   }
' ----- END ASM ReadDWordAtPointer -----
'
' ----- POINTER to use In CallAsmProc -----
'       A Bit Faster than Calling ReadDWordAtPointer
DefInt ptrReadDWordAtPointer
ptrReadDWordAtPointer = VarPtr (ReadDWordAtPointerArray(0))
'
' ----- RQ CALL ReadDWordAtPointer -----
Function ReadDWordAtPointer (pointer As Long) As Long
    Result = CallAsmProc (ptrReadDWordAtPointer, pointer, 0, 0, 0)
End Function
'
' ============================================================
'
' ============================================================
' ----- START ASM ReadWordAtPointer -----
DefByte ReadWordAtPointerArray (0 To 22) = _
   { _
    &HC8, &H00, &H00, &H00, &H56, &H8B, &H75, &H08, &H8B, &H36,  _
    &HB8, &H00, &H00, &H00, &H00, &H66, &H8B, &H06, &H5E, &HC9,  _
    &HC2, &H10, &H00 _
   }
' ----- END ASM ReadWordAtPointer -----
'
' ----- POINTER to use In CallAsmProc -----
'       A Bit Faster than Calling ReadWordAtPointer
DefInt ptrReadWordAtPointer
ptrReadWordAtPointer = VarPtr (ReadWordAtPointerArray(0))
'
' ----- RQ CALL ReadWordAtPointer -----
Function ReadWordAtPointer (pointer As Long) As Long
    Result = CallAsmProc (ptrReadWordAtPointer, pointer, 0, 0, 0)
End Function
'
' ============================================================
'
' ============================================================
' ----- START ASM ReadByteAtPointer -----
DefByte ReadByteAtPointerArray (0 To 21) = _
   { _
    &HC8, &H00, &H00, &H00, &H56, &H8B, &H75, &H08, &H8B, &H36,  _
    &HB8, &H00, &H00, &H00, &H00, &H8A, &H06, &H5E, &HC9, &HC2,  _
    &H10, &H00 _
   }
' ----- END ASM ReadByteAtPointer -----
'
' ----- POINTER to use In CallAsmProc -----
'       A Bit Faster than Calling ReadByteAtPointer
DefInt ptrReadByteAtPointer
ptrReadByteAtPointer = VarPtr (ReadByteAtPointerArray(0))
'
' ----- RQ CALL ReadByteAtPointer -----
Function ReadByteAtPointer (pointer As Long) As Long
    Result = CallAsmProc (ptrReadByteAtPointer, pointer, 0, 0, 0)
End Function
'
' ============================================================
'
' ============================================================
' ----- START ASM WriteDWordAtAddress -----
DefByte WriteDWordAtAddressArray (0 To 17) = _
   { _
    &HC8, &H00, &H00, &H00, &H57, &H8B, &H7D, &H08, &H8B, &H45,  _
    &H0C, &H89, &H07, &H5F, &HC9, &HC2, &H10, &H00 _
   }
' ----- END ASM WriteDWordAtAddress -----
'
' ----- POINTER to use In CallAsmProc -----
'       A Bit Faster than Calling WriteDWordAtAddress
DefInt ptrWriteDWordAtAddress
ptrWriteDWordAtAddress = VarPtr (WriteDWordAtAddressArray(0))
'
' ----- RQ CALL WriteDWordAtAddress -----
Function WriteDWordAtAddress (address As Long, dwData As Long) As Long
    Result = CallAsmProc (ptrWriteDWordAtAddress, address, dwData, 0, 0)
End Function
'
' ============================================================
'
' ============================================================
' ----- START ASM WriteWordAtAddress -----
DefByte WriteWordAtAddressArray (0 To 23) = _
   { _
    &HC8, &H00, &H00, &H00, &H57, &H8B, &H7D, &H08, &H8B, &H45,  _
    &H0C, &H25, &HFF, &HFF, &H00, &H00, &H66, &H89, &H07, &H5F,  _
    &HC9, &HC2, &H10, &H00 _
   }
' ----- END ASM WriteWordAtAddress -----
'
' ----- POINTER to use In CallAsmProc -----
'       A Bit Faster than Calling WriteWordAtAddress
DefInt ptrWriteWordAtAddress
ptrWriteWordAtAddress = VarPtr (WriteWordAtAddressArray(0))
'
' ----- RQ CALL WriteWordAtAddress -----
Function WriteWordAtAddress (address As Long, wData As Long) As Long
    Result = CallAsmProc (ptrWriteWordAtAddress, address, wData, 0, 0)
End Function
'
' ============================================================
'
' ============================================================
' ----- START ASM WriteByteAtAddress -----
DefByte WriteByteAtAddressArray (0 To 22) = _
   { _
    &HC8, &H00, &H00, &H00, &H57, &H8B, &H7D, &H08, &H8B, &H45,  _
    &H0C, &H25, &HFF, &H00, &H00, &H00, &H88, &H07, &H5F, &HC9,  _
    &HC2, &H10, &H00 _
   }
' ----- END ASM WriteByteAtAddress -----
'
' ----- POINTER to use In CallAsmProc -----
'       A Bit Faster than Calling WriteByteAtAddress
DefInt ptrWriteByteAtAddress
ptrWriteByteAtAddress = VarPtr (WriteByteAtAddressArray(0))
'
' ----- RQ CALL WriteByteAtAddress -----
Function WriteByteAtAddress (address As Long, bData As Long) As Long
    Result = CallAsmProc (ptrWriteByteAtAddress, address, bData, 0, 0)
End Function
'
' ============================================================
'
' ============================================================
' ----- START ASM WriteDWordAtPointer -----
DefByte WriteDWordAtPointerArray (0 To 19) = _
   { _
    &HC8, &H00, &H00, &H00, &H57, &H8B, &H7D, &H08, &H8B, &H3F,  _
    &H8B, &H45, &H0C, &H89, &H07, &H5F, &HC9, &HC2, &H10, &H00 _
   }
' ----- END ASM WriteDWordAtPointer -----
'
' ----- POINTER to use In CallAsmProc -----
'       A Bit Faster than Calling WriteDWordAtPointer
DefInt ptrWriteDWordAtPointer
ptrWriteDWordAtPointer = VarPtr (WriteDWordAtPointerArray(0))
'
' ----- RQ CALL WriteDWordAtPointer -----
Function WriteDWordAtPointer (pointer As Long, dwData As Long) As Long
    Result = CallAsmProc (ptrWriteDWordAtPointer, pointer, dwData, 0, 0)
End Function
'
' ============================================================
'
' ============================================================
' ----- START ASM WriteWordAtPointer -----
DefByte WriteWordAtPointerArray (0 To 25) = _
   { _
    &HC8, &H00, &H00, &H00, &H57, &H8B, &H7D, &H08, &H8B, &H3F,  _
    &H8B, &H45, &H0C, &H25, &HFF, &HFF, &H00, &H00, &H66, &H89,  _
    &H07, &H5F, &HC9, &HC2, &H10, &H00 _
   }
' ----- END ASM WriteWordAtPointer -----
'
' ----- POINTER to use In CallAsmProc -----
'       A Bit Faster than Calling WriteWordAtPointer
DefInt ptrWriteWordAtPointer
ptrWriteWordAtPointer = VarPtr (WriteWordAtPointerArray(0))
'
' ----- RQ CALL WriteWordAtPointer -----
Function WriteWordAtPointer (pointer As Long, wData As Long) As Long
    Result = CallAsmProc (ptrWriteWordAtPointer, pointer, wData, 0, 0)
End Function
'
' ============================================================
'
' ============================================================
' ----- START ASM WriteByteAtPointer -----
DefByte WriteByteAtPointerArray (0 To 24) = _
   { _
    &HC8, &H00, &H00, &H00, &H57, &H8B, &H7D, &H08, &H8B, &H3F,  _
    &H8B, &H45, &H0C, &H25, &HFF, &H00, &H00, &H00, &H88, &H07,  _
    &H5F, &HC9, &HC2, &H10, &H00 _
   }
' ----- END ASM WriteByteAtPointer -----
'
' ----- POINTER to use In CallAsmProc -----
'       A Bit Faster than Calling WriteByteAtPointer
DefInt ptrWriteByteAtPointer
ptrWriteByteAtPointer = VarPtr (WriteByteAtPointerArray(0))
'
' ----- RQ CALL WriteByteAtPointer -----
Function WriteByteAtPointer (pointer As Long, bData As Long) As Long
    Result = CallAsmProc (ptrWriteByteAtPointer, pointer, bData, 0, 0)
End Function
'
' ============================================================
'
$ENDIF   ' IncManager: __RQASMUTILS_INC
