'WinMM.DLL Functions
'FILE ADDED: Release Version 1
'FILE UPDATED: Release Version 1

'Adapted for RapidQ by Bryn Mosher (bdmnky@hotmail.com)
'WIN32API RapidQ $Includes
'Home page - http://home.pacbell.net/brynm/
'RapidQ - http://www.basicguru.com/abc/rapidq/


'MCIGetERrorString()

	Declare Function MCIGetErrorString Lib "winmm.dll" Alias_
	 "mciGetErrorStringA" (dwError As Long, lpstrBuffer As String, uLength As Long) As Long


'MCSSendString()

	Declare Function MCISendString Lib "winmm.dll" Alias_
	 "mciSendStringA" (lpstrCommand As String, lpstrReturnString As String,_
	 uReturnLength As Long, hwndCallback As Long) As Long


'TimeGetTime()
	'Gets time since system started
	'EXAMPLE:
		'ShowMessage ( "Seconds since boot up: " + Str$(TimeGetTime)

	Declare Function timeGetTime Lib "winmm.dll" Alias_
	 "timeGetTime" As Long

