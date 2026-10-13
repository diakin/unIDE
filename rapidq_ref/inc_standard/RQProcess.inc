$IFNDEF __RQPROCESS_INC   ' IncManager: include guard
$DEFINE __RQPROCESS_INC

'===== From Message #27265 Thu Sep 8, 2005 9:53 am ======
'Michel Jose Facen
'I'm designing a Internet Coin Mechanism program for Intenet Cafиs ,
'I'm using the wonderful RapidQ for programming it, I got a Visual
'Basic copy a couple of years ago and still prefer to do it with rq !
'I need to kill another process before exiting the program, I'm using
'lots of api calls in my program, I'll paste just the ones related to
'the task. The problem is I can't close the other process. I can get
'the process Id to know if its running but I cant close it up. Please
'someone help me out, I've been stuck for days and can't understand
'what I'm doing wrong.
'Here is the code, most of it is from contributions of this site :



CONST NUM_PROCESSES = 1024
CONST NUM_MODULES = 1
CONST NAME_LENGTH = 256

CONST NULL = 0
CONST FALSE = 0
CONST TRUE = 1

CONST DELETE = &H00010000
CONST READ_CONTROL = &H00020000
CONST WRITE_DAC = &H00040000
CONST WRITE_OWNER = &H00080000
CONST SYNCHRONIZE = &H00100000

CONST STANDARD_RIGHTS_REQUIRED = &H000F0000

CONST STANDARD_RIGHTS_READ = READ_CONTROL
CONST STANDARD_RIGHTS_WRITE = READ_CONTROL
CONST STANDARD_RIGHTS_EXECUTE = READ_CONTROL

CONST STANDARD_RIGHTS_ALL = &H001F0000

CONST SPECIFIC_RIGHTS_ALL = &H0000FFFF

CONST PROCESS_TERMINATE = &H0001
CONST PROCESS_CREATE_THREAD = &H0002
CONST PROCESS_SET_SESSIONID = &H0004
CONST PROCESS_VM_OPERATION = &H0008
CONST PROCESS_VM_READ = &H0010
CONST PROCESS_VM_WRITE = &H0020
CONST PROCESS_DUP_HANDLE = &H0040
CONST PROCESS_CREATE_PROCESS = &H0080
CONST PROCESS_SET_QUOTA = &H0100
CONST PROCESS_SET_INFORMATION = &H0200
CONST PROCESS_QUERY_INFORMATION = &H0400
CONST PROCESS_SUSPEND_RESUME = &H0800
CONST PROCESS_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED OR SYNCHRONIZE OR &HFFF


DECLARE FUNCTION EnumProcesses LIB "psapi" ALIAS "EnumProcesses" _
( arrayPointer AS LONG,  arraySize AS LONG, BYREF arrayUsed AS LONG) AS LONG

DECLARE FUNCTION EnumProcessModules LIB "psapi" ALIAS "EnumProcessModules" _
( processHandle AS LONG,  arrayPointer AS LONG,  arraySize AS LONG, _
BYREF arrayUsed AS LONG) AS LONG

DECLARE FUNCTION GetModuleBaseName LIB "psapi" ALIAS "GetModuleBaseNameA" _
( processHandle AS LONG,  moduleHandle AS LONG, BYREF name AS STRING,  nameSize AS LONG) AS LONG

DECLARE FUNCTION OpenProcess LIB "kernel32" ALIAS "OpenProcess" _
(desiredAccess AS LONG, inheritHandle AS LONG, pid AS LONG) AS LONG

DECLARE FUNCTION CloseHandle LIB "kernel32" ALIAS "CloseHandle" _
( handle AS LONG) AS LONG

DECLARE FUNCTION GetLastError LIB "kernel32" ALIAS "GetLastError" AS LONG

Declare Function TerminateProcess Lib "kernel32" alias "TerminateProcess" _
( hProcess As Long,  uExitCode As Long)  As Long

Declare Sub ExitProcess Lib "kernel32" alias "ExitProcess" ( uExitCode As Long)

Declare Function GetExitCodeProcess Lib "kernel32" Alias "GetExitCodeProcess" _
( hProcess As Long, lpExitCode As Long) As Long


DECLARE FUNCTION CreateAPIString(length AS LONG) AS STRING
DECLARE FUNCTION ReadAPIString(str AS STRING, length AS LONG) AS STRING
DECLARE FUNCTION ReadNullTermString(str AS STRING) AS STRING

DECLARE FUNCTION FindProcessId(name AS STRING) AS LONG
DECLARE SUB PrintProcessInfo(pid AS LONG, text AS STRING)

'
'######## THIS IS JUST A LITLE CONSOLE APP TO SHOW WHAT I #########' NEED TO DO.
'# Main # IT SHOULD CLOSE NOTEPAD AS SOON AS IT IS OPENED
'######## IT FINDS THE procID ALLRIGHT BUT DOESN'T KILL NOTEPAD

DIM procId AS LONG : dim procExit as long


'#############
'# Functions #
'#############

'*****************************************
FUNCTION CreateAPIString(length AS LONG) AS STRING
Result = SPACE$(length)
END FUNCTION

'*****************************************
FUNCTION ReadAPIString(str AS STRING, length AS LONG) AS STRING
DIM realLength AS LONG
realLength = LEN(str)

IF length < realLength THEN
	realLength = length
END IF

Result = LEFT$(str, realLength)
END FUNCTION

'*****************************************
FUNCTION ReadNullTermString(str AS STRING) AS STRING
DEFINT i

FOR i = 1 TO LEN(str)
	IF (ASC(str[i]) = NULL) THEN
		Result = LTRIM$(RTRIM$(LEFT$(str, i - 1)))
		EXIT FOR
	END IF
NEXT i
END FUNCTION

'*****************************************
FUNCTION FindProcessId(name AS STRING) AS LONG
name = UCASE$(name)
'print"name=";name
DIM processes(NUM_PROCESSES) AS LONG, size AS LONG, procUsed AS LONG
size = NUM_PROCESSES * SIZEOF(LONG)

EnumProcesses(VARPTR(processes(0)), size, procUsed)

procUsed = procUsed / SIZEOF(LONG)

Result = -1

DEFINT i
FOR i = 0 TO procUsed - 1
	DIM pid AS LONG, pHandle AS LONG
	pid = processes(i)
	
	pHandle = OpenProcess(PROCESS_QUERY_INFORMATION OR PROCESS_VM_READ,FALSE, pid) ' PROCESS_ALL_ACCESS
	'pHandle = OpenProcess(PROCESS_TERMINATE , TRue, pid) ' PROCESS_ALL_ACCESS
	
	'print procUsed
	
	
	DIM module AS LONG, modSize AS LONG, modUsed AS LONG
	module = 0
	modSize = SIZEOF(LONG)
	modUsed = 0
	
	IF (EnumProcessModules(pHandle, VARPTR(module), modSize, modUsed) <> NULL) THEN
		
		DIM modName AS STRING, nameSize AS LONG
		modName = CreateAPIString(NAME_LENGTH)
		nameSize = NAME_LENGTH
		
		GetModuleBaseName(pHandle, module, modName, nameSize)
		modName = ReadNullTermString(modName)
		
		CloseHandle(pHandle)
		
		IF (UCASE$(modName) = name) THEN
			Result = pid
			procExit = pHandle
			
		END IF
	END IF
	
NEXT i
END FUNCTION


'*****************************************
FUNCTION rqTerminateProcess ( procID AS long ) AS LONG
	if procID <> -1 then 
	pHandle=OpenProcess (PROCESS_TERMINATE, 0,procID)
	'print"pHandle=";pHandle
	zzx=TerminateProcess( pHandle , 0 )
	'print"zzx=";zzx
	
	zzc=CloseHandle (pHandle) 
	'print"zzc=";zzc
	rqTerminateProcess=zzc
	else
	rqTerminateProcess=0
	end if
END FUNCTION

'--------- example -------------
'print rqTerminateProcess (FindProcessId("calc.exe"))



$ENDIF   ' IncManager: __RQPROCESS_INC
