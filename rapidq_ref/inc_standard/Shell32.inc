$IFNDEF __SHELL32_INC   ' IncManager: include guard
$DEFINE __SHELL32_INC
'Shell32.dll Functions
'FILE ADDED: Release Version 1
'FILE UPDATED: Release Version 2

'Adapted for RapidQ by Bryn Mosher (bdmnky@hotmail.com)
'WIN32API RapidQ $Includes 
'Home page - http://home.pacbell.net/brynm/
'RapidQ - http://www.basicguru.com/abc/rapidq/


'FindExecutable()
	'Needs a wrapper

	Declare Function FindExecutable Lib "shell32.dll" Alias_
	 "FindExecutableA" (lpFile As String, lpDirectory As String, lpResult As String) As Long


'SHEmptyRecycleBin()
	'SHQuerryRecycleBin() should be called first, but this kinda works

	Declare Function SHEmptyRecycleBin Lib "shell32.dll" Alias_
	 "SHEmptyRecycleBinA" (hwnd As Long, pszRootPath As String, dwFlags As Long) As Long


'SHQueryRecycleBin()
	'This hasn't been adapted yet. NT (which I run) uses SIDs to control folder names :(
	'Anyone else want to tackle it?

	Type shLong64
		shVar1 As Long
		shVar2 As Long
	End Type
	Type SHQUERYRBINFO
		cbSize As Long
		i64Size As Long
		i64NumItems As Long
	End Type

	Declare Function SHQueryRecycleBin Lib "shell32.dll" Alias_
	 "SHQueryRecycleBinA" (pszRootPath As Long, pSHQueryRBInfo As SHQUERYRBINFO) As Long

$ENDIF   ' IncManager: __SHELL32_INC
