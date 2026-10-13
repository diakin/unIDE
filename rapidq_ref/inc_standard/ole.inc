$IFNDEF __OLE_INC   ' IncManager: include guard
$DEFINE __OLE_INC
'******************************************************************************
'  Windows Object linking Environment (OLE)
'
'  http://sern.ucalgary.ca/Courses/CPSC/547/W2000/webnotes/COM/COM.html - intro to com
'  http://www.stolles.net/fsu-swt/LV/CompSem2000/works/COM-paper.pdf - details of COM
'  
'  The COM library provides a way for clients to start an object's server.
'  The client (your program) calls the COM library function CoCreateInstance. This request 
'  specifies the CLSID of the object to create and the IID of an interface 
'  that the object supports. The COM library uses the object'  s CLSID to locate 
'  the correct server. The registry maps CLSIDs to actual server code. This 
'  mapping includes the CLSID as the key, an indication of the types of servers 
'  available, and for in-process and local servers, a pathname for the file 
'  with the server's DLL or exe. For remote servers, the pathname is replaced 
'  with an indication of where to find the exe. Once the object is running, it 
'  passes a pointer to that object back to the client, which can then use that 
'  pointer to access the object. 
'  Summary
'  -Your program calls CoCreateInstance
'  -The "COM library" finds the CLSID for the DLL file through the system registry
'  -The Call then instantiates the "Server" object (starts it up, loads in memory)
'  -A pointer to the interface is returned to a method in the object
'******************************************************************************'

$TYPECHECK ON

$IFNDEF __OLE_INC
$DEFINE __OLE_INC

$DEFINE EC_COMPLETE               &h1
$DEFINE CLSCTX_INPROC_SERVER      1&
$DEFINE CLSCTX_INPROC_HANDLER     2&
$DEFINE CLSCTX_LOCAL_SERVER       4&
$DEFINE CLSCTX_REMOTE_SERVER      16&
$DEFINE CLSCTX_NO_CODE_DOWNLOAD   400&
$DEFINE CLSCTX_NO_FAILURE_LOG     4000&
CONST CLSCTX_SERVER             AS LONG = CLSCTX_INPROC_SERVER  OR CLSCTX_LOCAL_SERVER OR CLSCTX_REMOTE_SERVER
CONST CLSCTX_ALL                AS LONG = CLSCTX_INPROC_HANDLER OR CLSCTX_SERVER
CONST CLSCTX_INPROC             AS LONG = CLSCTX_INPROC_SERVER  OR CLSCTX_INPROC_HANDLER
$DEFINE S_OK                      0&

Type GUID
   Data1 As Long	 	 '4 bytes
   Data2 As WORD		 '2 bytes 
   Data3 As WORD		 '2 bytes
   Data4 As STRING * 8	 'Data4(0 To 7) As Byte '8 bytes
End Type


''extract binary code from string like "{e436ebb3-524f-11ce-9f53-0020af0ba770}"
FUNCTION GUID$(ClassID AS STRING) AS STRING
    DIM i       AS INTEGER
    DIM Data(8) As Word         'use word instead of long to prevent overflow on CONVBASE$
    DIM RtnStr  AS STRING: RtnStr = SPACE$(16)

    ClassID = UCASE$(ClassID)
    if INSTR(ClassID," ") then ClassID = REPLACESUBSTR$(ClassID," ","")
    if INSTR(ClassID,"{") then ClassID = REPLACESUBSTR$(ClassID,"{","")
    if INSTR(ClassID,"{") then ClassID = REPLACESUBSTR$(ClassID,"}","")
    if INSTR(ClassID,":") then ClassID = REPLACESUBSTR$(ClassID,":","")
    if INSTR(ClassID,"CLSID") then ClassID = REPLACESUBSTR$(ClassID,"CLSID","")
'    if INSTR(ClassID,"-") then ClassID = REPLACESUBSTR$(ClassID,"-","")

    IF LEFT$(ClassID,1) = "{" THEN ClassID = MID$(ClassID, 2, LEN(ClassID)-1)
    IF RIGHT$(ClassID,1) = "}" THEN ClassID = LEFT$(ClassID, LEN(ClassID)-1)
     Data(0) = VAL(CONVBASE$( MID$(ClassID, 5, 4), 16, 10))
     Data(1) = VAL(CONVBASE$( MID$(ClassID, 1, 4), 16, 10))
     Data(2) = VAL(CONVBASE$( MID$(ClassID, 10, 4), 16, 10))
     Data(3) = VAL(CONVBASE$( MID$(ClassID, 15, 4), 16, 10))
     Data(4) = VAL(CONVBASE$( MID$(ClassID, 22, 2) + MID$(ClassID, 20, 2), 16 , 10))
     Data(5) = VAL(CONVBASE$( MID$(ClassID, 27, 2) + MID$(ClassID, 25, 2), 16 , 10))
     Data(6) = VAL(CONVBASE$( MID$(ClassID, 31, 2) + MID$(ClassID, 29, 2), 16 , 10))
     Data(7) = VAL(CONVBASE$( MID$(ClassID, 35, 2) + MID$(ClassID, 33, 2), 16 , 10))
    MEMCPY (VarPtr(RtnStr),VARPTR(Data(0)), 16)
    RESULT = RtnStr
END FUNCTION


Declare Function StringFromGUID2 Lib "ole32.dll" ALIAS "StringFromGUID2"(rclsid As GUID, ByVal lpsz As Long, ByVal cbMax As Long) As Long
Declare Function CLSIDFromProgID Lib "ole32.dll" ALIAS "CLSIDFromProgID"(ByVal lpszProgID As Long, pCLSID As GUID) As Long
Declare Function CLSIDFromProgIDEx Lib "ole32.dll" ALIAS "CLSIDFromProgIDEx"(ByVal lpszProgID As Long, pCLSID As GUID) As Long
Declare Function ProgIDFromCLSID Lib "ole32.dll" ALIAS "ProgIDFromCLSID"(pCLSID As GUID, lpszProgID As Long) As Long
Declare Function StringFromCLSID Lib "ole32.dll" ALIAS "StringFromCLSID"(pCLSID As GUID, lpszProgID As Long) As Long
'Declare Function CLSIDFromString Lib "ole32.dll" ALIAS "CLSIDFromString"(ByVal lpszProgID As Long, pCLSID As GUID) As Long
Declare Function IIDFromString   Lib "ole32.dll" ALIAS "IIDFromString"(ByVal lpsz As String, ByRef lpiid As GUID) As Long

'eg, IIDFromString "{000214E6-0000-0000-C000-000000000046}", iidShellFolder
Declare Function CoCreateGuid    Lib "ole32.dll" ALIAS "CoCreateGuid" (lpGUID as GUID) as Long
Declare Sub CoUninitialize       Lib "ole32.dll" ALIAS "CoUninitialize" ()
Declare Function CoInitialize    Lib "ole32.dll" ALIAS "CoInitialize" (ByVal pvReserved As Long) As Long
declare function OleInitialize   lib "ole32.dll" alias "OleInitialize" (pvReserved as long) as long 
declare sub OleUninitialize      lib "ole32.dll" alias "OleUninitialize" 


Declare Function IsEqualGUID Lib "ole32.dll" ALIAS "IsEqualGUID"(rguid1 As GUID, rguid2 As GUID) As Long 
' Declare Function CoCreateInstance Lib "ole32" ALIAS "CoCreateInstance"( _
'     ByVal rclsid As String, ByVal pUnkOuter As Long, _
'     ByVal dwClsContext As Long, ByVal riid As String, _
'     ByRef ppv As DWORD) As Long

' converted so that ref parameters take a long pointer     
Declare Function CoCreateInstance Lib "ole32" ALIAS "CoCreateInstance"( _
    rclsid As Long, pUnkOuter As Long, _
    dwClsContext As Long, riid As long, _
    ppv As long) As Long


'------------------------------------------------------------
'   Convert a binary GUID to a string representation of a GUID
'------------------------------------------------------------
Function GuidStringFromGUID(rclsid As GUID) As String
    Dim rc As Long
    Dim stGuid As String * 40

    ' 39 chars  for the GUID and terminate with Null char
    stGuid = String$(40, 0&)
    rc = StringFromGUID2(rclsid, VARPTR(stGuid), (Len(stGuid) - 1))
    GuidStringFromGUID = Left$(stGuid, rc - 1)
End Function


'code to call the COM procedure vtable via pointer to pointer
'====================================================================================
$IFNDEF CALL_ASM_PROC_X
$DEFINE CALL_ASM_PROC_X
    DECLARE FUNCTION CallAsmProc LIB "user32" ALIAS "CallWindowProcA" _
    (Proc AS LONG, A1 AS LONG, A2 AS LONG, A3 AS LONG, A4 AS LONG) AS LONG
$ENDIF
'
'
'====================================================================================
' ----- ARRAY containing ASM MCALLasm -----
'this is an assembly code section written by Jacques Phillpe for loading an array
'of paramters, placing them on the stack and calling a function pointer. This is to
'be used in jumping to COM function pointers in RapidQ
DefByte MCALLasmArray (0 To 51) = _
    {&H55,&H89,&HE5,&H8B,&H75,&H08,&H8B,&H06,&H89,&HC3,&HC1,&HE0,&H02,&H01,&HC6,&H81,_
    &HFB,&H00,&H00,&H00,&H00,&H74,&H0B,&HFF,&H36,&H81,&HEE,&H04,&H00,&H00,&H00,&H4B,_
    &H75,&HF5,&H8B,&H45,&H0C,&H8B,&H4D,&H10,&H50,&H8B,&H00,&HFF,&H14,&H08,&H89,&HEC,_
    &H5D,&HC2,&H10,&H00}

' ----- POINTER to use In CallAsmProc -----
DefInt ptrMCALLasm = VarPtr (MCALLasmArray(0))
'
'====================================================================================
' Argument order : 
'   ObjectPtr As Long, 
'   MethodName (or offset) As Long, 
'   Arg1 As Long, Arg2 As Long, ..., ArgN As Long
'   example MCALL(lpDirectDraw, DD_Flip, 0)
Functioni MCALL (...) As Long
  DefInt N
  Dim Arg(0 To (ParamValCount - 2)) As Long

  If ParamValCount > 1 Then               'check argument count good
        Arg(0) = ParamValCount - 2          ' Arg Number
        If ParamValCount > 2 Then
          For N = 3 To ParamValCount
            Arg(N - 2) = ParamVal(N)        'load up parameters from Functioni
          Next N
        End If
'    Param(1) = ObjectPtr, Param(2) = MethodName, then call the function pointer address
    Result = CallAsmProc (ptrMCALLasm, VarPtr(Arg(0)), ParamVal(1), ParamVal(2), 0)
   End If
End Functioni
'
'====================================================================================
' ---- RQ CODE END ----

$ENDIF		'__OLE_INC
$ENDIF   ' IncManager: __OLE_INC
