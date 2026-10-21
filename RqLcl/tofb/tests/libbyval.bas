$APPTYPE CONSOLE
' 64-bit build: ByVal 0& to a record parameter of DECLARE ... LIB
' (CreateFile in RQdebugger) and DEFINT x = CODEPTR(Proc) (NewWndProc.Inc)
TYPE SECURITYATTRIBUTES
  nLength AS DWORD
  lpSecurityDescriptor AS LONG
  bInheritHandle AS LONG
END TYPE
DECLARE FUNCTION CreateFile LIB "kernel32" ALIAS "CreateFileA" (lpFileName AS STRING, dwDesiredAccess AS DWORD, dwShareMode AS DWORD, lpSecurityAttributes AS SECURITYATTRIBUTES, dwCreationDisposition AS DWORD, dwFlagsAndAttributes AS DWORD, hTemplateFile AS LONG) AS LONG
DECLARE FUNCTION CloseHandle LIB "kernel32" ALIAS "CloseHandle" (hObject AS LONG) AS LONG
DECLARE FUNCTION Twice (Value AS LONG) AS LONG
DEFINT lpTwice = CODEPTR(Twice)
DIM hDevice AS LONG
DIM fname AS STRING
fname = "libbyval.tmp"
hDevice = CreateFile(fname, &H40000000, &H1 Or &H2, ByVal 0&, 2, 0, 0)
IF hDevice <> -1 THEN PRINT "createfile ok" ELSE PRINT "createfile failed"
CloseHandle(hDevice)
PRINT "exists "; FILEEXISTS(fname)
KILL fname
PRINT "codeptr "; (lpTwice <> 0)
PRINT "end"
FUNCTION Twice (Value AS LONG) AS LONG
  Twice = Value * 2
END FUNCTION
